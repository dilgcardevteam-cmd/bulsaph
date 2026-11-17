# Pocketwise

A phone-friendly money tracker and planner that stores your data in this browser on this device. It does not need an account or send financial data to a server.

## Open it locally

1. Start Apache in XAMPP.
2. On the computer, open `http://localhost/fundapp/`.
3. On your phone connected to the same Wi-Fi, open `http://<computer-local-IP>/fundapp/` (allow Apache through your local firewall if needed).
4. Use your browser's **Add to Home Screen** option to install Pocketwise.

The app shell works offline after its first successful load. Transactions and settings are saved by the browser; clearing the browser's site data will erase them.

## Install the Android app

The ready-to-install debug APK is `Pocketwise.apk` in this folder. Copy it to your Android phone (USB, cloud drive, or another file transfer), open it, and allow your file app or browser to install unknown apps if Android asks. This is a locally built debug APK for personal installation; it is not published on Google Play.

If Android blocks the install, check that the APK transfer completed and that you enabled **Install unknown apps** for the app you used to open it.

## Open the Android simulator

From PowerShell in this project folder, run `.\start-simulator.ps1`. It starts the Pixel 8 virtual device, installs the current APK, and opens Pocketwise. The first boot may take a minute or two. Close the simulator window when you are done.

## Rebuild after changing the app

Run `.uild-apk.ps1` in PowerShell. This syncs the web app into Android, builds a debug APK, and copies the result to `Pocketwise.apk`. The project-local Java and Android SDK used for the build are under `.build-tools`.

## Included

- Monthly income, spending, and balance summary
- Income and expense entries with dates and categories
- Category spending limits with progress indicators
- A savings goal with an add-to-goal flow
- Loan monitoring with deadlines, remaining balances, and payment tracking
- Month navigation and activity filters
- Philippine peso formatting by default
