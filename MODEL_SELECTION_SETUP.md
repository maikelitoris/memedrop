# 3D Container Model Selection Feature

## Overview
Users can now select which 3D model (sealed container) appears on the home screen. Each container type can give different prizes in the future.

## Files Modified

### 1. `lib/widgets/sealed_container.dart`
- Added `containerType` parameter to specify which GLB model to load
- Dynamic model loading: `src: 'assets/models/${widget.containerType}.glb'`

### 2. `lib/screens/home_screen.dart`
- Added `_containerModels` list with available models: `['brain', 'pepe_compressed']`
- Added `_selectedContainer` state variable (defaults to 'brain')
- Passes `containerType` to `SealedContainer` widget

### 3. `lib/screens/settings_screen.dart`
- Added container selection UI with dropdown menu
- Loads/saves selected container via `CollectionService`

### 4. `lib/services/collection_service.dart`
- Added `_containerKey` for SharedPreferences storage
- Added `getSelectedContainer()` - returns saved model or 'brain' default
- Added `setSelectedContainer(String)` - persists user's choice

## How to Add a New Model

1. **Place the GLB file** in `/workspace/assets/models/`:
   ```
   your_model_name.glb
   ```

2. **Update the model list** in both files:
   - `lib/screens/home_screen.dart` line ~31:
     ```dart
     static const List<String> _containerModels = [
       'brain',
       'pepe_compressed',
       'your_model_name', // Add here
     ];
     ```
   - `lib/screens/settings_screen.dart` line ~31:
     ```dart
     static const List<String> _containerModels = [
       'brain',
       'pepe_compressed',
       'your_model_name', // Add here
     ];
     ```

3. **Done!** The model will appear in the Settings dropdown and render when selected.

## Model Requirements
- Format: `.glb` (binary glTF)
- Recommended size: < 2MB for mobile performance
- Camera orbit: Models should fit within 2.5m radius
- Textures: Use compressed textures (KTX2/Basis) for best performance

## Current Models
- `brain.glb` - Default container (already included)
- `pepe_compressed.glb` - **TODO: Add this file**

## Usage
1. Open the app
2. Go to Settings (gear icon)
3. Find "CONTAINER" setting
4. Select desired model from dropdown
5. Return to home screen - your selected 3D model will be displayed
