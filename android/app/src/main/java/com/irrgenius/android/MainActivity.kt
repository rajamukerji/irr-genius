package com.irrgenius.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.irrgenius.android.data.DataManager
import com.irrgenius.android.data.models.CalculationMode
import com.irrgenius.android.ui.components.*
import com.irrgenius.android.ui.screens.*
import com.irrgenius.android.ui.theme.IRRGeniusTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            IRRGeniusTheme {
                MainTabScreen()
            }
        }
    }
}

enum class AppTab(
    val route: String,
    val title: String,
    val icon: ImageVector
) {
    CALCULATOR("calculator", "Calculator", Icons.Default.Calculate),
    SAVED("saved", "Saved", Icons.Default.Folder),
    PROJECTS("projects", "Projects", Icons.Default.FolderSpecial),
    SETTINGS("settings", "Settings", Icons.Default.Settings)
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainTabScreen() {
    val navController = rememberNavController()
    val context = androidx.compose.ui.platform.LocalContext.current
    val dataManager = remember { DataManager(context) }
    
    Scaffold(
        bottomBar = {
            NavigationBar {
                val navBackStackEntry by navController.currentBackStackEntryAsState()
                val currentDestination = navBackStackEntry?.destination
                
                AppTab.values().forEach { tab ->
                    NavigationBarItem(
                        icon = { Icon(tab.icon, contentDescription = tab.title) },
                        label = { Text(tab.title) },
                        selected = currentDestination?.hierarchy?.any { it.route == tab.route } == true,
                        onClick = {
                            navController.navigate(tab.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = AppTab.CALCULATOR.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(AppTab.CALCULATOR.route) {
                CalculatorTabScreen()
            }
            composable(AppTab.SAVED.route) {
                SavedCalculationsScreen(dataManager = dataManager)
            }
            composable(AppTab.PROJECTS.route) {
                ProjectsScreen(dataManager = dataManager)
            }
            composable(AppTab.SETTINGS.route) {
                SettingsScreen()
            }
        }
    }
}

@Composable
fun CalculatorTabScreen(
    viewModel: MainViewModel = viewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        // Header
        HeaderView()
        
        // Mode Selector
        ModeSelectorView(
            selectedMode = uiState.calculationMode,
            onModeSelected = { mode -> viewModel.setCalculationMode(mode) }
        )
        
        // Content based on selected mode
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            when (uiState.calculationMode) {
                CalculationMode.CALCULATE_IRR -> IRRCalculationView(uiState, viewModel)
                CalculationMode.CALCULATE_OUTCOME -> OutcomeCalculationView(uiState, viewModel)
                CalculationMode.CALCULATE_INITIAL -> InitialCalculationView(uiState, viewModel)
                CalculationMode.CALCULATE_BLENDED -> BlendedIRRCalculationView(uiState, viewModel)
                CalculationMode.PORTFOLIO_UNIT_INVESTMENT -> PortfolioUnitInvestmentView(uiState, viewModel)
            }
        }
    }
    
    // Portfolio Follow-on Investment Modal
    if (uiState.showingAddPortfolioInvestment) {
        AddPortfolioFollowOnInvestmentView(
            onDismiss = { viewModel.setShowingAddPortfolioInvestment(false) },
            onAdd = { investment ->
                viewModel.addPortfolioFollowOnInvestment(investment)
                viewModel.setShowingAddPortfolioInvestment(false)
            },
            initialInvestmentDate = uiState.portfolioInitialDate
        )
    }
}



