import { App } from '@capacitor/app';
import { registerPlugin } from '@capacitor/core';

const NativeBiometric = registerPlugin('LocalBiometrics');

window.BulsaNative = { App, NativeBiometric };
