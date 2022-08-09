package org.apache.cordova.inappbrowser.javascriptinterface;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Base64;
import android.webkit.JavascriptInterface;

import org.apache.cordova.LOG;
import org.apache.cordova.inappbrowser.InAppBrowser;
import org.apache.cordova.inappbrowser.file.FileHelper;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.Date;

public class BlobDownloadJavaScriptInterface {
    protected static final String LOG_TAG = "BlobDownloadJavaScriptInterface";

    private Context context;
    private InAppBrowser inAppBrowser;
    public BlobDownloadJavaScriptInterface(InAppBrowser inAppBrowser, Context context) {
        this.inAppBrowser = inAppBrowser;
        this.context = context;
    }

    @JavascriptInterface
    public void getBase64FromBlobData(String base64Data, String mimeType) throws IOException {
        this.inAppBrowser.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    convertBase64StringToFileAndStoreIt(base64Data, mimeType);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        });
    }

    public static Boolean supports(String blobUrl) {
        return blobUrl.startsWith("blob");
    }

    public static String getBase64StringFromBlobUrl(String blobUrl) {
        if (BlobDownloadJavaScriptInterface.supports(blobUrl)) {
            return "javascript: var xhr = new XMLHttpRequest();" +
                    "xhr.open('GET', '"+ blobUrl +"', true);" +
                    // "xhr.setRequestHeader('Content-type','application/pdf');" +
                    "xhr.responseType = 'blob';" +
                    "xhr.onload = function(e) {" +
                    "    if (this.status == 200) {" +
                    "        let blob = this.response;" +
                    "        let reader = new FileReader();" +
                    "        reader.readAsDataURL(blob);" +
                    "        reader.onloadend = function() {" +
                    "            let base64data = reader.result;" +
                    "            BlobDownloadJavaScriptInterface.getBase64FromBlobData(base64data, blob.type);" +
                    "        }" +
                    "    }" +
                    "};" +
                    "xhr.send();";
        }

        return "console.log('It is not a Blob URL');";
    }

    private void convertBase64StringToFileAndStoreIt(String base64Data, String mimeType) throws IOException {
        LOG.d(LOG_TAG, base64Data);

        byte[] fileAsBytes = Base64.decode(base64Data.replaceFirst("^data:" + mimeType + ";base64,", ""), 0);

        String folder = Environment.DIRECTORY_DOWNLOADS;
        SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy_MM_dd_HH_mm_ss");
        String filename = "download_" + simpleDateFormat.format(new Date());

        String filePath = "";

        if (Build.VERSION.SDK_INT >= 29) {
            ContentValues contentValues = new ContentValues();
            contentValues.put(MediaStore.MediaColumns.DISPLAY_NAME, filename);
            contentValues.put(MediaStore.MediaColumns.MIME_TYPE, mimeType);
            contentValues.put(MediaStore.MediaColumns.RELATIVE_PATH, folder);

            ContentResolver resolver = context.getContentResolver();
            Uri uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues);
            // if (uri != null) {
                OutputStream output = resolver.openOutputStream(uri);
                output.write(fileAsBytes);
                output.close();

                filePath = FileHelper.getRealPathFromURI(context, uri);
            // }
        } else {
            String extension = FileHelper.getMimeTypeExtensionMapping().getOrDefault(mimeType, "");

            filePath = Environment.getExternalStoragePublicDirectory(folder)
                + "/"
                + filename
                + extension
            ;

            final File dwldsPath = new File(filePath);

            FileOutputStream os;
            os = new FileOutputStream(dwldsPath, false);
            os.write(fileAsBytes);
            os.flush();
        }

        try {
            JSONObject data = new JSONObject();
            data.put("path", filePath);
            data.put("mimeType", mimeType);

            JSONObject obj = new JSONObject();
            obj.put("type", InAppBrowser.DOWNLOAD_END_EVENT);
            obj.put("data", data);
            inAppBrowser.sendUpdate(obj, true);
        } catch(Exception e) {
            LOG.e(LOG_TAG, "Error sending " + InAppBrowser.DOWNLOAD_END_EVENT);
        }
    }
}
