#!/bin/bash
set -e  # Exit on any error

# Use the requirejs optimizer r.js to optimise js files

# Will deploy the site the ./docs directory in the current branch.

echo ""
echo "=== Deploying to ./docs directory ==="
echo ""


if [ ! -d "./docs" ]; then
  mkdir docs
fi

if [ -d tmp ]; then
  BUILD_DIR="./tmp"
else
  mkdir tmp
  BUILD_DIR="./tmp"
fi



rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Skip RequireJS optimization - it uses old UglifyJS that can't handle modern ES6+ syntax
# The site loads modules directly via RequireJS, so optimization isn't critical for beta
echo "Copying files to build directory..."
# Use rsync or tar to avoid copying tmp into itself
tar --exclude='./tmp' --exclude='./.git' --exclude='./docs' -cf - . | (cd "$BUILD_DIR" && tar -xf -)

# Replace $GIT_COMMIT with the git commit hash in all php files
GIT_COMMIT=$(git rev-parse HEAD)

echo "git commit is $GIT_COMMIT"

cd $BUILD_DIR

# Find HTML files to process (fix: was using >> before find command)
find cslEditorLib/pages -name "*.html" > filesToConvert 2>/dev/null || true
find . -maxdepth 2 -name "index.html" >> filesToConvert 2>/dev/null || true

# Replace $GIT_COMMIT in HTML files
if [ -s filesToConvert ]; then
	while read FILENAME;
	do
		if [ -f "$FILENAME" ]; then
			echo "converting $FILENAME"
			sed s/\$GIT_COMMIT/$GIT_COMMIT/g <$FILENAME >tempFile
			mv tempFile $FILENAME
		fi
	done < filesToConvert
fi
rm -f filesToConvert

# Remove any *.php files in external libraries
find external -name "*.php" -type f -print0 2>/dev/null | xargs -0 rm -f || true
find cslEditorLib/external -name "*.php" -type f -print0 2>/dev/null | xargs -0 rm -f || true

# Run Jekyll
jekyll build

#don't use docs directory in build
rm -rf ./_site/docs

#clean up docs directory
rm -rf ../docs/*
cd ../docs


cp -r ../tmp/_site/* ./

cd ..
# Clean up
rm -rf "$BUILD_DIR"

echo ""
echo "=== Build complete! ==="
echo ""
echo "Review changes with: git status"
echo "To commit and push: git add --all && git commit -m 'deploy' && git push"
echo ""


