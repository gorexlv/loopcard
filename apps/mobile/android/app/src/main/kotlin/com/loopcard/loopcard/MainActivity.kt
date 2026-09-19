package com.loopcard.loopcard

import android.speech.tts.TextToSpeech
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val speechChannel = "com.loopcard.loopcard/speech"
    private var textToSpeech: TextToSpeech? = null
    private var speechReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        textToSpeech = TextToSpeech(this, this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, speechChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "speak") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val text = call.argument<String>("text")?.trim().orEmpty()
                val region = call.argument<String>("region").orEmpty()
                val engine = textToSpeech
                if (!speechReady || engine == null || text.isEmpty()) {
                    result.success(false)
                    return@setMethodCallHandler
                }
                engine.language = when (region) {
                    "UK" -> Locale.UK
                    else -> Locale.US
                }
                val status = engine.speak(
                    text,
                    TextToSpeech.QUEUE_FLUSH,
                    null,
                    "loopcard-${System.currentTimeMillis()}",
                )
                result.success(status == TextToSpeech.SUCCESS)
            }
    }

    override fun onInit(status: Int) {
        speechReady = status == TextToSpeech.SUCCESS
        if (speechReady) textToSpeech?.language = Locale.US
    }

    override fun onDestroy() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        super.onDestroy()
    }
}
