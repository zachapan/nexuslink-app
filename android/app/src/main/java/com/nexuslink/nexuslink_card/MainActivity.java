package com.nexuslink.nexuslink_card;

import android.content.Intent;
import android.nfc.NfcAdapter;
import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);

        // Μεταβίβαση NFC intents στο Flutter
        String action = intent.getAction();
        if (action != null && (
                action.equals(NfcAdapter.ACTION_NDEF_DISCOVERED) ||
                        action.equals(NfcAdapter.ACTION_TAG_DISCOVERED) ||
                        action.equals(NfcAdapter.ACTION_TECH_DISCOVERED))) {

            setIntent(intent);
        }
    }
}