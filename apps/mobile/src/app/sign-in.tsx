import * as Linking from 'expo-linking';
import { Redirect, router } from 'expo-router';
import * as WebBrowser from 'expo-web-browser';
import { useState } from 'react';
import { KeyboardAvoidingView, Platform, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Field } from '@/components/Frame';
import { Button, Dashed, Highlight, Paper, Txt, useIsWide } from '@/components/ui';
import { hasBackend, supabase } from '@/lib/supabase';
import { useSession } from '@/state/session';
import { fonts, space, type, usePalette } from '@/theme/tokens';

WebBrowser.maybeCompleteAuthSession();

/** The mechanism, printed: what the app does, shown on a receipt (sample data). */
function MiniReceipt() {
  const p = usePalette();
  const row = (a: string, b: string, muted?: string) => (
    <View style={styles.rRow}>
      <View style={{ flex: 1 }}>
        <Text style={[type.mono, { color: p.ink }]}>{a}</Text>
        {muted ? <Text style={[type.mono, { color: p.inkMuted, fontSize: 11 }]}>{muted}</Text> : null}
      </View>
      <Text style={[type.mono, { color: p.ink }]}>{b}</Text>
    </View>
  );
  return (
    <Paper style={{ width: '100%', maxWidth: 360, alignSelf: 'center', transform: [{ rotate: '-1.2deg' }] }}>
      <Text style={[type.monoStrong, { color: p.ink, textAlign: 'center', letterSpacing: 2 }]}>MEALMATE</Text>
      <Text style={[type.mono, { color: p.inkMuted, textAlign: 'center', fontSize: 11 }]}>Beispiel · 2 Personen</Text>
      <Dashed />
      {row('Blattspinat', '1 × 450 g', 'Mo 200 g · Mi 250 g')}
      {row('Schlagsahne', '1 × 200 ml', 'Bedarf 150 ml')}
      <Highlight>
        {row('REST Sahne 50 ml', 'verplant', '→ Fr Tomatensuppe')}
      </Highlight>
      <Dashed />
      <View style={styles.rRow}>
        <Text style={[type.monoStrong, { color: p.ink, flex: 1 }]}>Übrig</Text>
        <Text style={[type.monoStrong, { color: p.ink }]}>0 g</Text>
      </View>
    </Paper>
  );
}

export default function SignIn() {
  const p = usePalette();
  const insets = useSafeAreaInsets();
  const wide = useIsWide();
  const { status, startGuest } = useSession();
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [sent, setSent] = useState(false);
  const [showCode, setShowCode] = useState(false);
  const [busy, setBusy] = useState<null | 'mail' | 'code' | 'google' | 'guest'>(null);
  const [error, setError] = useState<string | null>(null);

  if (status === 'ready') return <Redirect href="/" />;

  const sendCode = async () => {
    setError(null);
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email.trim())) return setError('Bitte gib eine gültige E-Mail-Adresse ein.');
    setBusy('mail');
    const { error: e } = await supabase!.auth.signInWithOtp({
      email: email.trim(),
      options: { shouldCreateUser: true, emailRedirectTo: Linking.createURL('/auth-callback') },
    });
    setBusy(null);
    if (e) return setError(e.message.includes('rate') ? 'Zu viele Versuche. Warte kurz und probier es erneut.' : 'Die Mail konnte nicht gesendet werden. Prüf die Adresse.');
    setSent(true);
  };

  const verify = async () => {
    setError(null);
    setBusy('code');
    const { error: e } = await supabase!.auth.verifyOtp({ email: email.trim(), token: code.trim(), type: 'email' });
    setBusy(null);
    if (e) return setError('Der Code stimmt nicht oder ist abgelaufen. Fordere einen neuen an.');
    router.replace('/');
  };

  const google = async () => {
    setError(null);
    setBusy('google');
    const redirectTo = Linking.createURL('/auth-callback');
    const { data, error: e } = await supabase!.auth.signInWithOAuth({ provider: 'google', options: { redirectTo, skipBrowserRedirect: Platform.OS !== 'web' } });
    if (e || !data.url) {
      setBusy(null);
      return setError('Google-Anmeldung ist gerade nicht verfügbar.');
    }
    if (Platform.OS !== 'web') {
      const res = await WebBrowser.openAuthSessionAsync(data.url, redirectTo);
      if (res.type === 'success') {
        const authCode = new URL(res.url).searchParams.get('code');
        if (authCode) await supabase!.auth.exchangeCodeForSession(authCode);
      }
      setBusy(null);
    }
  };

  const guest = async () => {
    setBusy('guest');
    await startGuest();
    router.replace('/');
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={{ flex: 1, backgroundColor: p.frame }}>
      <ScrollView contentContainerStyle={[styles.page, wide && styles.pageWide, { paddingTop: insets.top + space.xl, paddingBottom: insets.bottom + space.xl }]} keyboardShouldPersistTaps="handled">
        <View style={[styles.hero, wide && { flex: 1 }]}>
          <Text accessibilityRole="header" style={{ fontFamily: fonts.display, fontSize: wide ? 88 : 60, lineHeight: wide ? 84 : 58, color: p.frameInk, letterSpacing: -1.5 }}>
            Kauf nur,{'\n'}was du isst.
          </Text>
          <Text style={[type.body, { color: p.frameInk, maxWidth: 420 }]}>
            MealMate rechnet deine Woche in echte Packungsgrößen um und plant jeden Rest gleich mit ein.
          </Text>
          {wide ? <MiniReceipt /> : null}
        </View>

        <Paper torn="both" style={[styles.card, wide && { width: 420 }]}>
          <View style={{ gap: space.lg }}>
            <Txt variant="headline">Anmelden</Txt>
            {hasBackend ? (
              <>
                {!sent ? (
                  <>
                    <Field label="E-Mail" placeholder="du@beispiel.de" autoCapitalize="none" autoComplete="email" keyboardType="email-address" inputMode="email" value={email} onChangeText={setEmail} onSubmitEditing={sendCode} error={error} />
                    <Button label="Anmelde-Link senden" onPress={sendCode} loading={busy === 'mail'} />
                  </>
                ) : (
                  <>
                    <Txt variant="body">
                      Wir haben dir eine Mail an <Txt variant="bodyStrong">{email.trim()}</Txt> geschickt. Tipp auf den Link darin. Öffne ihn{' '}
                      {Platform.OS === 'web' ? 'in diesem Browser' : 'auf diesem Gerät'}, dann bist du direkt angemeldet.
                    </Txt>
                    <Txt variant="small" color="inkMuted">Keine Mail da? Schau im Spam-Ordner nach. Neue Mails gehen erst nach ein paar Minuten raus.</Txt>
                    {showCode ? (
                      <>
                        <Field label="Code aus der Mail" placeholder="123456" mono keyboardType="number-pad" inputMode="numeric" autoComplete="one-time-code" maxLength={8} value={code} onChangeText={setCode} onSubmitEditing={verify} error={error} />
                        <Button label="Mit Code anmelden" onPress={verify} loading={busy === 'code'} disabled={code.trim().length < 6} />
                      </>
                    ) : (
                      <Button label="Die Mail enthält einen Code" variant="ghost" compact onPress={() => setShowCode(true)} />
                    )}
                    <Button label="Andere E-Mail verwenden" variant="ghost" compact onPress={() => { setSent(false); setCode(''); setShowCode(false); setError(null); }} />
                  </>
                )}
                <View style={styles.or}>
                  <View style={[styles.orLine, { backgroundColor: p.rule }]} />
                  <Txt variant="small" color="inkMuted">oder</Txt>
                  <View style={[styles.orLine, { backgroundColor: p.rule }]} />
                </View>
                <Button label="Mit Google anmelden" variant="secondary" onPress={google} loading={busy === 'google'} />
              </>
            ) : (
              <Txt variant="body" color="inkMuted">Für diese Installation ist kein Server eingerichtet. Du kannst MealMate trotzdem vollständig ausprobieren.</Txt>
            )}
            <Dashed style={{ marginVertical: 0 }} />
            <Button label="Ohne Konto ausprobieren" variant="ghost" onPress={guest} loading={busy === 'guest'} accessibilityHint="Deine Daten bleiben nur auf diesem Gerät." />
            <Txt variant="small" color="inkMuted" style={{ textAlign: 'center' }}>Ohne Konto bleiben deine Daten nur auf diesem Gerät.</Txt>
          </View>
        </Paper>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  page: { flexGrow: 1, paddingHorizontal: space.lg, gap: space.xxl, justifyContent: 'center', width: '100%', maxWidth: 1120, alignSelf: 'center' },
  pageWide: { flexDirection: 'row', alignItems: 'center', gap: 72, paddingHorizontal: space.xxxl },
  hero: { gap: space.xl },
  card: { alignSelf: 'stretch' },
  or: { flexDirection: 'row', alignItems: 'center', gap: space.md },
  orLine: { flex: 1, height: 1 },
  rRow: { flexDirection: 'row', alignItems: 'flex-start', gap: space.md, paddingVertical: 3 },
});
