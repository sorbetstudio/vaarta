package studio.sorbet.vaarta.assist

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.Window
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.Button
import android.widget.TextView
//import android.widget.Toast
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.ViewGroup
import android.view.animation.Animation
import android.view.animation.TranslateAnimation
import android.os.Handler
import android.os.Looper

class AssistActivity : Activity() {

    companion object {
        const val TAG = "AssistActivity"

        private const val EXTRA_START_LISTENING = "start_listening"
        private const val EXTRA_FROM_FRONTEND = "from_frontend"

        fun newInstance(
            context: Context,
            startListening: Boolean = true,
            fromFrontend: Boolean = true
        ): Intent {
            return Intent(context, AssistActivity::class.java).apply {
                putExtra(EXTRA_START_LISTENING, startListening)
                putExtra(EXTRA_FROM_FRONTEND, fromFrontend)

                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION)
            }
        }
    }

    private lateinit var assistContainer: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Completely disable enter animation
        overridePendingTransition(0, 0)

        // Remove title bar
        requestWindowFeature(Window.FEATURE_NO_TITLE)

        // Configure window for translucency and overlay
        window.setFlags(
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL
        )

        // Set a semi-transparent background
        window.setBackgroundDrawableResource(android.R.color.transparent)

        // Use FrameLayout as the root to properly position elements
        val rootLayout = FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            // Semi-transparent black overlay
            setBackgroundColor(Color.argb(100, 0, 0, 0))
        }

        // Get parameters
        val startListening = intent.getBooleanExtra(EXTRA_START_LISTENING, true)
        val fromFrontend = intent.getBooleanExtra(EXTRA_FROM_FRONTEND, true)

        // Create assistant container
        assistContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.BOTTOM
                setMargins(30, 0, 30, 50)
            }
            // Initially hide the container (will be shown with animation)
            visibility = View.INVISIBLE
        }

        // Create a gradient background container
        val gradientContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            setPadding(30, 30, 30, 30)

            // Gradient background with transparency
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 50f
                setColors(intArrayOf(
                    Color.argb(230, 74, 144, 226),   // Translucent light blue
                    Color.argb(230, 80, 163, 226)    // Translucent slightly different blue
                ))
                orientation = GradientDrawable.Orientation.TOP_BOTTOM
            }
        }

        // Add listening indicator
        val listeningText = TextView(this).apply {
            text = "Listening..."
            setTextColor(Color.WHITE)
            textSize = 18f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 20)
        }
        gradientContainer.addView(listeningText)

        // Add info text
        val infoText = TextView(this).apply {
            text = "What can I help you with?"
            setTextColor(Color.WHITE)
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 30)
        }
        gradientContainer.addView(infoText)

        // Add close button
        val closeButton = Button(this).apply {
            text = "Cancel"
            setTextColor(Color.WHITE)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 30f
                setColor(Color.argb(200, 63, 81, 181)) // Translucent indigo
            }
            setOnClickListener {
                animateDown()
            }
        }
        gradientContainer.addView(closeButton)

        // Add gradient container to assist container
        assistContainer.addView(gradientContainer)

        // Add assist container to root layout
        rootLayout.addView(assistContainer)

        // Set the content view
        setContentView(rootLayout)

        // Show a toast to indicate the assistant is ready
//        Toast.makeText(this, "Assistant is ready", Toast.LENGTH_SHORT).show()

        // Start animation after a short delay to ensure proper layout
        Handler(Looper.getMainLooper()).postDelayed({
            animateUp()
        }, 100)
    }

    private fun animateUp() {
        // Make the container visible before animation
        assistContainer.visibility = View.VISIBLE

        // Offset is exactly the height of the view (moves from completely below screen to visible)
        val animation = TranslateAnimation(0f, 0f, assistContainer.height.toFloat(), 0f).apply {
            duration = 300
            fillAfter = false
        }

        assistContainer.startAnimation(animation)
    }

    private fun animateDown() {
        // Explicitly calculate the distance to move (height of the container)
        val animation = TranslateAnimation(0f, 0f, 0f, assistContainer.height.toFloat()).apply {
            duration = 300
            fillAfter = true

            setAnimationListener(object : Animation.AnimationListener {
                override fun onAnimationStart(animation: Animation?) {}
                override fun onAnimationRepeat(animation: Animation?) {}
                override fun onAnimationEnd(animation: Animation?) {
                    finish()
                }
            })
        }

        assistContainer.startAnimation(animation)
    }

    override fun onPause() {
        super.onPause()
        // Completely disable exit animation
        overridePendingTransition(0, 0)
    }
}