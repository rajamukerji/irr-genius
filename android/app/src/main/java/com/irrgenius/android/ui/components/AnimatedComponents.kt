package com.irrgenius.android.ui.components

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.ripple.rememberRipple
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.irrgenius.android.ui.theme.*

// MARK: - Animated Button
@OptIn(ExperimentalAnimationApi::class)
@Composable
fun AnimatedButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    style: ButtonStyle = ButtonStyle.Primary,
    size: ButtonSize = ButtonSize.Medium,
    isLoading: Boolean = false,
    isEnabled: Boolean = true
) {
    var isPressed by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.98f else 1f,
        animationSpec = tween(durationMillis = AnimationDuration.Quick),
        label = "button_scale"
    )
    
    val elevation by animateDpAsState(
        targetValue = if (isPressed) 2.dp else 4.dp,
        animationSpec = tween(durationMillis = AnimationDuration.Quick),
        label = "button_elevation"
    )
    
    Button(
        onClick = onClick,
        modifier = modifier
            .scale(scale)
            .shadow(
                elevation = elevation,
                shape = RoundedCornerShape(CornerRadius.sm),
                ambientColor = style.backgroundColor.copy(alpha = 0.3f),
                spotColor = style.backgroundColor.copy(alpha = 0.3f)
            )
            .pointerInput(Unit) {
                detectTapGestures(
                    onPress = {
                        isPressed = true
                        tryAwaitRelease()
                        isPressed = false
                    }
                )
            },
        enabled = isEnabled && !isLoading,
        colors = ButtonDefaults.buttonColors(
            containerColor = style.backgroundColor,
            contentColor = style.contentColor,
            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant,
            disabledContentColor = MaterialTheme.colorScheme.onSurfaceVariant
        ),
        contentPadding = size.padding,
        shape = RoundedCornerShape(CornerRadius.sm)
    ) {
        AnimatedContent(
            targetState = isLoading,
            transitionSpec = {
                fadeIn(animationSpec = tween(AnimationDuration.Smooth)) with
                fadeOut(animationSpec = tween(AnimationDuration.Smooth))
            },
            label = "button_content"
        ) { loading ->
            if (loading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(size.iconSize),
                    color = style.contentColor,
                    strokeWidth = 2.dp
                )
            } else {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    icon?.let {
                        Icon(
                            imageVector = it,
                            contentDescription = null,
                            modifier = Modifier.size(size.iconSize)
                        )
                    }
                    
                    Text(
                        text = text,
                        style = size.textStyle,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}

// MARK: - Floating Action Button
@OptIn(ExperimentalAnimationApi::class)
@Composable
fun AnimatedFloatingActionButton(
    onClick: () -> Unit,
    icon: ImageVector,
    modifier: Modifier = Modifier,
    backgroundColor: Color = IRRColors.PrimaryBlue,
    contentColor: Color = Color.White,
    isExtended: Boolean = false,
    text: String? = null
) {
    var isPressed by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.95f else 1f,
        animationSpec = spring(dampingRatio = Spring.DampingRatioMediumBouncy),
        label = "fab_scale"
    )
    
    val elevation by animateDpAsState(
        targetValue = if (isPressed) 4.dp else 8.dp,
        animationSpec = tween(durationMillis = AnimationDuration.Quick),
        label = "fab_elevation"
    )
    
    FloatingActionButton(
        onClick = onClick,
        modifier = modifier
            .scale(scale)
            .pointerInput(Unit) {
                detectTapGestures(
                    onPress = {
                        isPressed = true
                        tryAwaitRelease()
                        isPressed = false
                    }
                )
            },
        containerColor = backgroundColor,
        contentColor = contentColor,
        elevation = FloatingActionButtonDefaults.elevation(
            defaultElevation = elevation,
            pressedElevation = elevation - 2.dp
        )
    ) {
        AnimatedContent(
            targetState = isExtended,
            transitionSpec = {
                slideInHorizontally(
                    animationSpec = tween(AnimationDuration.Smooth),
                    initialOffsetX = { if (targetState) it else -it }
                ) + fadeIn() with
                slideOutHorizontally(
                    animationSpec = tween(AnimationDuration.Smooth),
                    targetOffsetX = { if (targetState) -it else it }
                ) + fadeOut()
            },
            label = "fab_content"
        ) { extended ->
            if (extended && text != null) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(imageVector = icon, contentDescription = null)
                    Text(text = text, fontWeight = FontWeight.Medium)
                }
            } else {
                Icon(imageVector = icon, contentDescription = null)
            }
        }
    }
}

// MARK: - Animated Card
@Composable
fun AnimatedCard(
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
    elevation: Dp = 4.dp,
    backgroundColor: Color = MaterialTheme.colorScheme.surface,
    contentColor: Color = MaterialTheme.colorScheme.onSurface,
    content: @Composable ColumnScope.() -> Unit
) {
    var isPressed by remember { mutableStateOf(false) }
    
    val scale by animateFloatAsState(
        targetValue = if (isPressed && onClick != null) 0.98f else 1f,
        animationSpec = tween(durationMillis = AnimationDuration.Quick),
        label = "card_scale"
    )
    
    val animatedElevation by animateDpAsState(
        targetValue = if (isPressed && onClick != null) elevation - 2.dp else elevation,
        animationSpec = tween(durationMillis = AnimationDuration.Quick),
        label = "card_elevation"
    )
    
    Card(
        modifier = modifier
            .scale(scale)
            .then(
                if (onClick != null) {
                    Modifier
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = rememberRipple()
                        ) { onClick() }
                        .pointerInput(Unit) {
                            detectTapGestures(
                                onPress = {
                                    isPressed = true
                                    tryAwaitRelease()
                                    isPressed = false
                                }
                            )
                        }
                } else Modifier
            ),
        elevation = CardDefaults.cardElevation(defaultElevation = animatedElevation),
        colors = CardDefaults.cardColors(
            containerColor = backgroundColor,
            contentColor = contentColor
        ),
        shape = RoundedCornerShape(CornerRadius.md),
        content = content
    )
}

// MARK: - Animated Segmented Control
@Composable
fun <T> AnimatedSegmentedControl(
    options: List<T>,
    selectedOption: T,
    onSelectionChange: (T) -> Unit,
    modifier: Modifier = Modifier,
    optionLabels: (T) -> String = { it.toString() }
) {
    val selectedIndex = options.indexOf(selectedOption)
    
    Row(
        modifier = modifier
            .background(
                MaterialTheme.colorScheme.surfaceVariant,
                RoundedCornerShape(CornerRadius.sm)
            )
            .padding(4.dp)
    ) {
        options.forEachIndexed { index, option ->
            val isSelected = index == selectedIndex
            
            Box(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(CornerRadius.sm))
                    .background(
                        animateColorAsState(
                            targetValue = if (isSelected) {
                                MaterialTheme.colorScheme.primary
                            } else {
                                Color.Transparent
                            },
                            animationSpec = tween(durationMillis = AnimationDuration.Smooth),
                            label = "segment_background"
                        ).value
                    )
                    .clickable { onSelectionChange(option) }
                    .padding(vertical = Spacing.sm, horizontal = Spacing.md),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = optionLabels(option),
                    color = animateColorAsState(
                        targetValue = if (isSelected) {
                            MaterialTheme.colorScheme.onPrimary
                        } else {
                            MaterialTheme.colorScheme.onSurfaceVariant
                        },
                        animationSpec = tween(durationMillis = AnimationDuration.Smooth),
                        label = "segment_text"
                    ).value,
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Normal
                )
            }
        }
    }
}

// MARK: - Animated Toggle
@Composable
fun AnimatedToggle(
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier,
    label: String? = null,
    enabled: Boolean = true
) {
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.spacedBy(Spacing.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        label?.let {
            Text(
                text = it,
                style = MaterialTheme.typography.bodyMedium,
                color = if (enabled) {
                    MaterialTheme.colorScheme.onSurface
                } else {
                    MaterialTheme.colorScheme.onSurfaceVariant
                },
                modifier = Modifier.weight(1f)
            )
        }
        
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            enabled = enabled,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = IRRColors.PrimaryGreen,
                uncheckedThumbColor = Color.White,
                uncheckedTrackColor = MaterialTheme.colorScheme.outline
            )
        )
    }
}

// MARK: - Progress Indicator
@Composable
fun AnimatedProgressIndicator(
    progress: Float,
    modifier: Modifier = Modifier,
    color: Color = IRRColors.PrimaryBlue,
    backgroundColor: Color = MaterialTheme.colorScheme.surfaceVariant,
    height: Dp = 4.dp
) {
    val animatedProgress by animateFloatAsState(
        targetValue = progress,
        animationSpec = tween(
            durationMillis = AnimationDuration.Slow,
            easing = EaseInOutCubic
        ),
        label = "progress"
    )
    
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .background(backgroundColor, RoundedCornerShape(height / 2))
    ) {
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .fillMaxWidth(animatedProgress)
                .background(color, RoundedCornerShape(height / 2))
        )
    }
}

// MARK: - Status Indicator
@Composable
fun StatusIndicator(
    status: StatusType,
    message: String,
    isVisible: Boolean,
    modifier: Modifier = Modifier
) {
    AnimatedVisibility(
        visible = isVisible,
        enter = slideInVertically(
            animationSpec = tween(AnimationDuration.Smooth),
            initialOffsetY = { -it }
        ) + fadeIn(),
        exit = slideOutVertically(
            animationSpec = tween(AnimationDuration.Smooth),
            targetOffsetY = { -it }
        ) + fadeOut(),
        modifier = modifier
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(
                    status.color.copy(alpha = 0.1f),
                    RoundedCornerShape(CornerRadius.sm)
                )
                .border(
                    1.dp,
                    status.color.copy(alpha = 0.3f),
                    RoundedCornerShape(CornerRadius.sm)
                )
                .padding(Spacing.md),
            horizontalArrangement = Arrangement.spacedBy(Spacing.sm),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = status.icon,
                contentDescription = null,
                tint = status.color,
                modifier = Modifier.size(20.dp)
            )
            
            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}

// MARK: - Supporting Data Classes
enum class ButtonStyle(val backgroundColor: Color, val contentColor: Color) {
    Primary(IRRColors.PrimaryBlue, Color.White),
    Secondary(Color.Transparent, IRRColors.PrimaryBlue),
    Tertiary(IRRColors.LightSurfaceVariant, IRRColors.LightOnSurfaceVariant),
    Destructive(IRRColors.Error, Color.White)
}

enum class ButtonSize(
    val padding: PaddingValues,
    val textStyle: androidx.compose.ui.text.TextStyle,
    val iconSize: Dp
) {
    Small(
        PaddingValues(horizontal = Spacing.sm, vertical = Spacing.xs),
        androidx.compose.ui.text.TextStyle(),
        16.dp
    ),
    Medium(
        PaddingValues(horizontal = Spacing.md, vertical = Spacing.sm),
        androidx.compose.ui.text.TextStyle(),
        20.dp
    ),
    Large(
        PaddingValues(horizontal = Spacing.lg, vertical = Spacing.md),
        androidx.compose.ui.text.TextStyle(),
        24.dp
    )
}

enum class StatusType(val color: Color, val icon: ImageVector) {
    Success(IRRColors.Success, Icons.Default.CheckCircle),
    Warning(IRRColors.Warning, Icons.Default.Warning),
    Error(IRRColors.Error, Icons.Default.Warning),
    Info(IRRColors.Info, Icons.Default.Info)
}