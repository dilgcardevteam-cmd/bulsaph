package ph.pocketwise.money;

import android.text.TextUtils;

import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "LocalBiometrics")
public class LocalBiometricsPlugin extends Plugin {
    @PluginMethod
    public void isAvailable(PluginCall call) {
        int result = BiometricManager.from(getContext())
            .canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK);
        JSObject response = new JSObject();
        response.put("isAvailable", result == BiometricManager.BIOMETRIC_SUCCESS);
        call.resolve(response);
    }

    @PluginMethod
    public void verifyIdentity(PluginCall call) {
        if (getActivity() == null) {
            call.reject("The app is not active. Try again when it is open.");
            return;
        }

        String title = call.getString("title");
        String subtitle = call.getString("subtitle");
        String description = call.getString("description");
        String cancelText = call.getString("negativeButtonText");
        if (TextUtils.isEmpty(title)) title = "Verify your identity";
        if (TextUtils.isEmpty(cancelText)) cancelText = "Cancel";

        BiometricPrompt.PromptInfo.Builder promptInfo = new BiometricPrompt.PromptInfo.Builder()
            .setTitle(title)
            .setNegativeButtonText(cancelText)
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_WEAK);
        if (!TextUtils.isEmpty(subtitle)) promptInfo.setSubtitle(subtitle);
        if (!TextUtils.isEmpty(description)) promptInfo.setDescription(description);

        BiometricPrompt prompt = new BiometricPrompt(
            getActivity(),
            ContextCompat.getMainExecutor(getContext()),
            new BiometricPrompt.AuthenticationCallback() {
                @Override
                public void onAuthenticationSucceeded(BiometricPrompt.AuthenticationResult result) {
                    call.resolve();
                }

                @Override
                public void onAuthenticationError(int errorCode, CharSequence errorMessage) {
                    call.reject(errorMessage.toString(), String.valueOf(errorCode));
                }
            }
        );
        getActivity().runOnUiThread(() -> prompt.authenticate(promptInfo.build()));
    }
}
