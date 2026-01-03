#!/usr/bin/env node

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const { pipeline } = require('stream');
const { promisify } = require('util');
const archiver = require('archiver');

const pipelineAsync = promisify(pipeline);

// Read version from pubspec.yaml
function getVersion() {
  const pubspecPath = path.join(__dirname, 'pubspec.yaml');
  const pubspec = fs.readFileSync(pubspecPath, 'utf8');
  const versionMatch = pubspec.match(/^version:\s*(.+?)(?:\+|$)/m);
  
  if (!versionMatch) {
    throw new Error('Could not find version in pubspec.yaml');
  }
  
  return versionMatch[1].trim();
}

// Copy directory recursively
function copyDirectory(src, dest) {
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
  }
  
  const entries = fs.readdirSync(src, { withFileTypes: true });
  
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    
    if (entry.isDirectory()) {
      copyDirectory(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

// Create zip archive
async function createZip(sourceDir, outPath) {
  return new Promise((resolve, reject) => {
    const output = fs.createWriteStream(outPath);
    const archive = archiver('zip', { zlib: { level: 9 } });
    
    output.on('close', () => {
      console.log(`Created zip: ${outPath} (${archive.pointer()} bytes)`);
      resolve();
    });
    
    archive.on('error', (err) => {
      reject(err);
    });
    
    archive.pipe(output);
    archive.directory(sourceDir, path.basename(sourceDir));
    archive.finalize();
  });
}

async function main() {
  console.log('Starting Windows build...');
  
  // Get version
  const version = getVersion();
  console.log(`Version: ${version}`);
  
  // Build Flutter app
  console.log('\nBuilding Flutter Windows app...');
  execSync('flutter build windows --release', {
    stdio: 'inherit',
    cwd: __dirname
  });
  
  // Define paths
  const buildOutputDir = path.join(__dirname, 'build', 'windows', 'x64', 'runner', 'Release');
  const deployDir = path.join(__dirname, 'deploy');
  const appFolderName = `Woodbine v${version}`;
  const targetDir = path.join(deployDir, appFolderName);
  const zipPath = path.join(deployDir, `${appFolderName}.zip`);
  
  // Check if executable exists
  const exePath = path.join(buildOutputDir, 'woodbine.exe');
  if (!fs.existsSync(exePath)) {
    throw new Error(`Executable not found at ${exePath}`);
  }
  
  console.log(`\nExecutable found: ${exePath}`);
  
  // Create deploy directory if it doesn't exist
  if (!fs.existsSync(deployDir)) {
    fs.mkdirSync(deployDir, { recursive: true });
  }
  
  // Remove existing target directory if it exists
  if (fs.existsSync(targetDir)) {
    console.log(`\nRemoving existing directory: ${targetDir}`);
    fs.rmSync(targetDir, { recursive: true, force: true });
  }
  
  // Copy build output to deploy directory
  console.log(`\nCopying build output to: ${targetDir}`);
  copyDirectory(buildOutputDir, targetDir);
  
  // Remove existing zip if it exists
  if (fs.existsSync(zipPath)) {
    console.log(`\nRemoving existing zip: ${zipPath}`);
    fs.unlinkSync(zipPath);
  }
  
  // Create zip
  console.log(`\nCreating zip archive...`);
  await createZip(targetDir, zipPath);
  
  console.log('\n✓ Build complete!');
  console.log(`  Deploy folder: ${targetDir}`);
  console.log(`  Zip file: ${zipPath}`);
}

main().catch((error) => {
  console.error('\n✗ Build failed:', error.message);
  process.exit(1);
});
