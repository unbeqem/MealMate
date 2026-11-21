// LLM provider abstraction (ADR-005). Claude first; a self-trained model plugs in as another provider.
import Anthropic from 'npm:@anthropic-ai/sdk@^0.140.0';

export interface RawRecipe {
  title: string;
  description: string;
  category: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  servings: number;
  prep_minutes: number;
  tags: string[];
  ingredients: { name: string; amount: number; unit: string; optional: boolean }[];
  steps: string[];
}

export interface GenerateInput {
  prompt: string;
  servings: number;
  maxMinutes: number | null;
  diet: string;
  allergens: string[];
  dislikes: string[];
  catalog: string[]; // known ingredient names, to steer the mapping
}

export interface RecipeModel {
  readonly provider: string;
  readonly model: string;
  generate(input: GenerateInput): Promise<RawRecipe>;
}

export class RefusedError extends Error {}

export const RECIPE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['title', 'description', 'category', 'servings', 'prep_minutes', 'tags', 'ingredients', 'steps'],
  properties: {
    title: { type: 'string' },
    description: { type: 'string' },
    category: { type: 'string', enum: ['breakfast', 'lunch', 'dinner', 'snack'] },
    servings: { type: 'integer' },
    prep_minutes: { type: 'integer' },
    tags: { type: 'array', items: { type: 'string' } },
    ingredients: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['name', 'amount', 'unit', 'optional'],
        properties: {
          name: { type: 'string' },
          amount: { type: 'number' },
          unit: { type: 'string', enum: ['g', 'kg', 'ml', 'l', 'EL', 'TL', 'Prise', 'Stk', 'Zehe', 'Bund', 'Dose', 'Scheibe', 'Handvoll', 'Kopf'] },
          optional: { type: 'boolean' },
        },
      },
    },
    steps: { type: 'array', items: { type: 'string' } },
  },
} as const;

const SYSTEM = `Du bist die Rezeptredaktion von MealMate, einer deutschen Wochenplaner-App für kleine Haushalte.
Schreibe alltagstaugliche, gelingsichere Rezepte auf Deutsch (du-Form) mit Zutaten aus deutschen Supermärkten.
Regeln:
- Verwende für Zutaten möglichst exakt die Namen aus dem Katalog. Erfinde nur dann eine neue Zutat, wenn es wirklich keine passende gibt.
- Mengen realistisch für die angegebenen Portionen. Gewürze, Salz, Pfeffer und Öl dürfen in kleinen Mengen vorkommen.
- Halte dich strikt an Ernährungsform, Allergien und Abneigungen. Wenn die Anfrage dem widerspricht, wähle eine passende Alternative.
- 3 bis 7 klare Schritte, jeweils ein bis zwei Sätze.
- Kurze Beschreibung (ein Satz), 1 bis 3 Tags in Kleinbuchstaben.`;

export class ClaudeProvider implements RecipeModel {
  readonly provider = 'anthropic';
  constructor(
    private readonly client: Anthropic,
    readonly model: string,
  ) {}

  async generate(input: GenerateInput): Promise<RawRecipe> {
    const user = [
      `Wunsch: ${input.prompt}`,
      `Portionen: ${input.servings}`,
      input.maxMinutes ? `Maximale Zubereitungszeit: ${input.maxMinutes} Minuten` : null,
      `Ernährungsform: ${input.diet}`,
      input.allergens.length ? `Allergien/Unverträglichkeiten (strikt meiden): ${input.allergens.join(', ')}` : null,
      input.dislikes.length ? `Mag nicht: ${input.dislikes.join(', ')}` : null,
      `Zutatenkatalog: ${input.catalog.join(', ')}`,
    ]
      .filter(Boolean)
      .join('\n');

    const response = await this.client.beta.messages.create({
      model: this.model,
      max_tokens: 16000,
      betas: ['server-side-fallback-2026-07-01'],
      fallbacks: 'default',
      system: SYSTEM,
      output_config: { effort: 'low', format: { type: 'json_schema', schema: RECIPE_SCHEMA } },
      messages: [{ role: 'user', content: user }],
    } as Anthropic.Beta.Messages.MessageCreateParamsNonStreaming);

    if (response.stop_reason === 'refusal') throw new RefusedError('Die Anfrage wurde vom Modell abgelehnt.');
    if (response.stop_reason === 'max_tokens') throw new Error('Antwort wurde abgeschnitten.');
    const text = response.content.find((b) => b.type === 'text');
    if (!text || text.type !== 'text') throw new Error('Keine Antwort vom Modell.');
    return JSON.parse(text.text) as RawRecipe;
  }
}

export function createRecipeModel(): RecipeModel {
  const provider = Deno.env.get('LLM_PROVIDER') ?? 'anthropic';
  if (provider === 'anthropic') {
    return new ClaudeProvider(new Anthropic(), Deno.env.get('LLM_MODEL') ?? 'claude-opus-5-5');
  }
  throw new Error(`Unbekannter LLM_PROVIDER: ${provider}`);
}
