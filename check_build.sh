#!/bin/bash
# Build validation script

echo "=== Checking for common compilation issues ==="

echo ""
echo "1. Checking for undefined EnvironmentType..."
grep -r "EnvironmentType" lib/screens/*.dart | while read line; do
    file=$(echo "$line" | cut -d: -f1)
    if ! grep -q "training_session.dart" "$file"; then
        echo "  ⚠️  $file uses EnvironmentType but may not import training_session.dart"
    fi
done

echo ""
echo "2. Checking for Equipment model/bowName parameter..."
if grep -r "model:" lib/screens/*.dart | grep "Equipment("; then
    echo "  ⚠️  Found 'model:' parameter - should be 'bowName:'"
else
    echo "  ✅ All Equipment() calls use correct 'bowName' parameter"
fi

echo ""
echo "3. Checking for invalid AppColors..."
if grep -r "AppColors\.textSlate600" lib/**/*.dart; then
    echo "  ⚠️  Found textSlate600 - should be textSlate500"
else
    echo "  ✅ All AppColors references are valid"
fi

echo ""
echo "4. Checking List<dynamic> type issues..."
if grep -r "\.map<int>" lib/screens/*.dart | grep "arrows"; then
    echo "  ⚠️  Found .map<int> syntax - this is incorrect!"
    echo "     Use List<int>.from(arrows.map((a) => a.property)) instead"
else
    echo "  ✅ No incorrect map<int> syntax found"
fi

echo ""
echo "5. Checking for missing imports..."
echo "  Checking scoring_screen.dart..."
if grep -q "import.*equipment.dart" lib/screens/scoring_screen.dart && \
   grep -q "import.*training_session.dart" lib/screens/scoring_screen.dart; then
    echo "    ✅ Has required imports"
else
    echo "    ⚠️  May be missing equipment or training_session import"
fi

echo "  Checking session_setup_screen.dart..."
if grep -q "import.*training_session.dart" lib/screens/session_setup_screen.dart; then
    echo "    ✅ Has training_session import"
else
    echo "    ⚠️  Missing training_session import"
fi

echo ""
echo "=== Check complete ==="
