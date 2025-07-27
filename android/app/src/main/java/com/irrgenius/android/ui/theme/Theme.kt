package com.irrgenius.android.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.unit.dp
import androidx.core.view.WindowCompat

// Extended Color Palette
object IRRColors {
    // Primary Colors
    val PrimaryBlue = Color(0xFF4A90E2)
    val PrimaryGreen = Color(0xFF50E3C2)
    val PrimaryOrange = Color(0xFFF5A623)
    
    // Semantic Colors
    val Success = Color(0xFF34C759)
    val Warning = Color(0xFFFF9500)
    val Error = Color(0xFFFF3B30)
    val Info = Color(0xFF5856D6)
    
    // Investment Colors
    val InvestmentPositive = Success
    val InvestmentNegative = Error
    val InvestmentNeutral = Color(0xFF8E8E93)
    
    // Light Theme Colors
    val LightBackground = Color(0xFFFFFBFE)
    val LightSurface = Color(0xFFFFFBFE)
    val LightSurfaceVariant = Color(0xFFF3F3F3)
    val LightOnBackground = Color(0xFF1C1B1F)
    val LightOnSurface = Color(0xFF1C1B1F)
    val LightOnSurfaceVariant = Color(0xFF49454F)
    val LightOutline = Color(0xFF79747E)
    
    // Dark Theme Colors
    val DarkBackground = Color(0xFF121212)
    val DarkSurface = Color(0xFF1E1E1E)
    val DarkSurfaceVariant = Color(0xFF2A2A2A)
    val DarkOnBackground = Color(0xFFE0E0E0)
    val DarkOnSurface = Color(0xFFE0E0E0)
    val DarkOnSurfaceVariant = Color(0xFFCAC4D0)
    val DarkOutline = Color(0xFF938F99)
}

// Spacing System
object Spacing {
    val xs = 4.dp
    val sm = 8.dp
    val md = 16.dp
    val lg = 24.dp
    val xl = 32.dp
    val xxl = 48.dp
    val xxxl = 64.dp
}

// Corner Radius System
object CornerRadius {
    val xs = 4.dp
    val sm = 8.dp
    val md = 12.dp
    val lg = 16.dp
    val xl = 24.dp
    val round = 50.dp
}

// Shapes
val IRRShapes = Shapes(
    extraSmall = RoundedCornerShape(CornerRadius.xs),
    small = RoundedCornerShape(CornerRadius.sm),
    medium = RoundedCornerShape(CornerRadius.md),
    large = RoundedCornerShape(CornerRadius.lg),
    extraLarge = RoundedCornerShape(CornerRadius.xl)
)

private val DarkColorScheme = darkColorScheme(
    primary = IRRColors.PrimaryBlue,
    secondary = IRRColors.PrimaryGreen,
    tertiary = IRRColors.PrimaryOrange,
    background = IRRColors.DarkBackground,
    surface = IRRColors.DarkSurface,
    surfaceVariant = IRRColors.DarkSurfaceVariant,
    onPrimary = Color.White,
    onSecondary = Color.Black,
    onTertiary = Color.Black,
    onBackground = IRRColors.DarkOnBackground,
    onSurface = IRRColors.DarkOnSurface,
    onSurfaceVariant = IRRColors.DarkOnSurfaceVariant,
    outline = IRRColors.DarkOutline,
    error = IRRColors.Error,
    onError = Color.White,
    errorContainer = IRRColors.Error.copy(alpha = 0.12f),
    onErrorContainer = IRRColors.Error,
)

private val LightColorScheme = lightColorScheme(
    primary = IRRColors.PrimaryBlue,
    secondary = IRRColors.PrimaryGreen,
    tertiary = IRRColors.PrimaryOrange,
    background = IRRColors.LightBackground,
    surface = IRRColors.LightSurface,
    surfaceVariant = IRRColors.LightSurfaceVariant,
    onPrimary = Color.White,
    onSecondary = Color.Black,
    onTertiary = Color.Black,
    onBackground = IRRColors.LightOnBackground,
    onSurface = IRRColors.LightOnSurface,
    onSurfaceVariant = IRRColors.LightOnSurfaceVariant,
    outline = IRRColors.LightOutline,
    error = IRRColors.Error,
    onError = Color.White,
    errorContainer = IRRColors.Error.copy(alpha = 0.12f),
    onErrorContainer = IRRColors.Error,
)

@Composable
fun IRRGeniusTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        shapes = IRRShapes,
        content = content
    )
}

// Status Colors Extension
@Composable
fun statusColor(isPositive: Boolean?, isNeutral: Boolean = false): Color {
    return when {
        isNeutral -> IRRColors.InvestmentNeutral
        isPositive == true -> IRRColors.InvestmentPositive
        isPositive == false -> IRRColors.InvestmentNegative
        else -> MaterialTheme.colorScheme.onSurface
    }
}

// Animation Durations
object AnimationDuration {
    const val Quick = 200
    const val Smooth = 300
    const val Slow = 500
}