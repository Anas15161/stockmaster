const fs = require('fs');
const path = require('path');

// --- CONFIGURATION ---
const LIB_DIR = './lib';
const OUTPUT_FILE = './docs/widgets_report.json';

// --- WIDGET CATEGORIES DB ---
const FLUTTER_WIDGETS = {
    layout: ['Scaffold', 'Container', 'Row', 'Column', 'Stack', 'Expanded', 'Flexible', 'Padding', 'Align', 'Center', 'SizedBox', 'SafeArea', 'Wrap', 'GridView', 'ListView', 'SingleChildScrollView', 'Card', 'Divider', 'Spacer'],
    navigation: ['Navigator', 'MaterialPageRoute', 'CupertinoPageRoute', 'BottomNavigationBar', 'TabBar', 'TabBarView', 'Drawer', 'AppBar', 'SliverAppBar'],
    inputs: ['Form', 'TextFormField', 'TextField', 'Checkbox', 'Switch', 'Radio', 'Slider', 'DropdownButton', 'DropdownButtonFormField', 'InkWell', 'GestureDetector', 'ElevatedButton', 'TextButton', 'OutlinedButton', 'IconButton', 'FloatingActionButton'],
    feedback: ['SnackBar', 'AlertDialog', 'SimpleDialog', 'BottomSheet', 'CircularProgressIndicator', 'LinearProgressIndicator', 'RefreshIndicator'],
    text_media: ['Text', 'RichText', 'Image', 'Icon', 'CircleAvatar'],
    async: ['FutureBuilder', 'StreamBuilder', 'StreamBuilder'],
    styling: ['Theme', 'MediaQuery', 'ClipRRect', 'DecoratedBox', 'Opacity', 'Transform'],
    state_management: ['Provider', 'Consumer', 'ChangeNotifierProvider', 'BlocBuilder', 'BlocProvider', 'GetBuilder', 'Obx']
};

const COMMON_EXCLUDES = ['print', 'debugPrint', 'super', 'setState', 'context', 'widget', 'mounted', 'Key', 'Color', 'EdgeInsets', 'BorderRadius', 'TextStyle', 'BoxDecoration'];

// --- HELPERS ---

function getAllFiles(dirPath, arrayOfFiles) {
    const files = fs.readdirSync(dirPath);
    arrayOfFiles = arrayOfFiles || [];

    files.forEach(function(file) {
        if (fs.statSync(dirPath + "/" + file).isDirectory()) {
            arrayOfFiles = getAllFiles(dirPath + "/" + file, arrayOfFiles);
        } else {
            if (file.endsWith('.dart')) {
                arrayOfFiles.push(path.join(dirPath, file));
            }
        }
    });
    return arrayOfFiles;
}

function getCategory(widgetName) {
    for (const [cat, list] of Object.entries(FLUTTER_WIDGETS)) {
        if (list.includes(widgetName)) return cat;
    }
    // Heuristic: If it ends with Screen, Page, View it's likely navigation/layout, otherwise Custom
    if (widgetName.endsWith('Screen') || widgetName.endsWith('Page')) return 'navigation';
    return 'custom';
}

function isScreen(fileName, fileContent) {
    const isScreenFile = /_screen\.dart$|_page\.dart$|_view\.dart$/.test(fileName.toLowerCase());
    const hasWidgetClass = /class\s+\w+\s+extends\s+(StatelessWidget|StatefulWidget|ConsumerWidget)/.test(fileContent);
    return isScreenFile || hasWidgetClass;
}

// --- MAIN LOGIC ---

console.log('🔍 Scanning ./lib folder for widgets...');

let globalStats = {
    pagesCount: 0,
    totalWidgetsDetected: 0,
    widgetsByCategory: {},
    topWidgets: {}
};

try {
    const files = getAllFiles(LIB_DIR);
    const pagesData = [];

    files.forEach(filePath => {
        const content = fs.readFileSync(filePath, 'utf8');
        const fileName = path.basename(filePath);

        if (!isScreen(fileName, content)) return;

        globalStats.pagesCount++;
        
        // Normalize path for display
        const displayPath = filePath.replace(/\\/g, '/');
        
        // Regex to find Widgets: CapitalLetter followed by letters/digits and an opening parenthesis
        const regex = /\b([A-Z][a-zA-Z0-9]*)\s*\(/g;
        let match;
        const lines = content.split('\n');
        const widgetsMap = new Map();

        while ((match = regex.exec(content)) !== null) {
            const widgetName = match[1];
            
            if (COMMON_EXCLUDES.includes(widgetName)) continue;

            // Find line number
            const charIndex = match.index;
            const lineNumber = content.substring(0, charIndex).split('\n').length;
            
            // Extract sample snippet
            const startLine = Math.max(0, lineNumber - 2);
            const endLine = Math.min(lines.length, lineNumber + 1);
            const sampleSnippet = lines.slice(startLine, endLine).join('\n');

            if (!widgetsMap.has(widgetName)) {
                widgetsMap.set(widgetName, {
                    name: widgetName,
                    count: 0,
                    category: getCategory(widgetName),
                    sampleLines: []
                });
            }

            const wData = widgetsMap.get(widgetName);
            wData.count++;
            if (wData.sampleLines.length < 3) {
                wData.sampleLines.push({ line: lineNumber, code: sampleSnippet });
            }
            
            // Update Global Stats
            globalStats.totalWidgetsDetected++;
            globalStats.widgetsByCategory[wData.category] = (globalStats.widgetsByCategory[wData.category] || 0) + 1;
            globalStats.topWidgets[widgetName] = (globalStats.topWidgets[widgetName] || 0) + 1;
        }

        const widgetsArray = Array.from(widgetsMap.values()).sort((a, b) => b.count - a.count);

        if (widgetsArray.length > 0) {
            pagesData.push({
                name: fileName.replace('.dart', ''),
                path: displayPath,
                widgets: widgetsArray,
                totalWidgetsDistinct: widgetsArray.length,
                totalWidgetsCount: widgetsArray.reduce((acc, curr) => acc + curr.count, 0)
            });
        }
    });

    // Sort global top widgets
    const sortedTopWidgets = Object.entries(globalStats.topWidgets)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 10)
        .map(([name, count]) => ({ name, count }));

    const report = {
        generatedAt: new Date().toISOString(),
        globalStats: {
            ...globalStats,
            topWidgets: sortedTopWidgets
        },
        pages: pagesData.sort((a, b) => b.totalWidgetsCount - a.totalWidgetsCount)
    };

    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(report, null, 2));
    console.log(`✅ Widget Report generated at ${OUTPUT_FILE}`);
    console.log(`   - Analyzed ${globalStats.pagesCount} screens/pages`);
    console.log(`   - Detected ${globalStats.totalWidgetsDetected} widget usages`);

} catch (e) {
    console.error("Error during scan:", e);
}
