import { Archivo_400Regular, Archivo_500Medium, Archivo_700Bold, Archivo_800ExtraBold } from '@expo-google-fonts/archivo';
import { ArchivoNarrow_600SemiBold, ArchivoNarrow_700Bold } from '@expo-google-fonts/archivo-narrow';
import { MartianMono_400Regular, MartianMono_600SemiBold } from '@expo-google-fonts/martian-mono';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createAsyncStoragePersister } from '@tanstack/query-async-storage-persister';
import { QueryClient } from '@tanstack/react-query';
import { PersistQueryClientProvider } from '@tanstack/react-query-persist-client';
import { useFonts } from 'expo-font';
import { Stack } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { Platform } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { SnackbarProvider } from '@/components/Sheet';
import { SessionProvider } from '@/state/session';
import { usePalette } from '@/theme/tokens';

SplashScreen.preventAutoHideAsync().catch(() => {});

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { gcTime: 1000 * 60 * 60 * 24 * 7, staleTime: 1000 * 30, retry: 1, networkMode: 'offlineFirst' },
    mutations: { networkMode: 'offlineFirst' },
  },
});
const persister = createAsyncStoragePersister({ storage: AsyncStorage, key: 'mm.query-cache' });

export default function RootLayout() {
  const [loaded, error] = useFonts({
    Archivo_400Regular,
    Archivo_500Medium,
    Archivo_700Bold,
    Archivo_800ExtraBold,
    ArchivoNarrow_600SemiBold,
    ArchivoNarrow_700Bold,
    MartianMono_400Regular,
    MartianMono_600SemiBold,
  });
  const p = usePalette();

  useEffect(() => {
    if (loaded || error) SplashScreen.hideAsync().catch(() => {});
  }, [loaded, error]);

  useEffect(() => {
    if (Platform.OS !== 'web') return;
    // browser surfaces carry the design too: selection, scrollbars, tabular figures
    const style = document.createElement('style');
    style.textContent = `::selection{background:#FFE45C;color:#2A2400}
      *{scrollbar-color:${p.rule} transparent;scrollbar-width:thin}
      input,textarea{caret-color:${p.accent}}
      input::placeholder,textarea::placeholder{color:${p.inkMuted};opacity:1}`;
    document.head.appendChild(style);
    document.documentElement.lang = 'de';
    return () => style.remove();
  }, [p]);

  if (!loaded && !error) return null;

  return (
    <SafeAreaProvider>
      <PersistQueryClientProvider client={queryClient} persistOptions={{ persister, maxAge: 1000 * 60 * 60 * 24 * 7 }}>
        <SessionProvider>
          <SnackbarProvider>
            <StatusBar style="light" />
            <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: p.ground }, animation: 'fade_from_bottom' }}>
              <Stack.Screen name="index" />
              <Stack.Screen name="sign-in" />
              <Stack.Screen name="onboarding" />
              <Stack.Screen name="(tabs)" />
              <Stack.Screen name="recipe/[id]" options={{ animation: 'slide_from_right' }} />
              <Stack.Screen name="generate" options={{ presentation: 'modal', animation: 'slide_from_bottom' }} />
            </Stack>
          </SnackbarProvider>
        </SessionProvider>
      </PersistQueryClientProvider>
    </SafeAreaProvider>
  );
}
