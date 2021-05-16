# Don't Starve Together Mod Notes
## Animation -> Spriter
### Scripts
- "D:\ktools-4.4.4\extract.py"
    - Extracts zip folders in the current directory under same folder name.
- "D:\ktools-4.4.4\krane.py"
    - Converts folders containing the bin/tex files (`anim/build/atlas`) to Spriter project under `<foldername>/spriter`
- "D:\ktools-4.4.4\ktech.py"
    - Converts atlas-0.tex files to png files under `<foldername>/atlas`
## Spriter -> Animation
1. Create a new folder under your mod named `exported`
2. Put all Spriter project files in `exported`
3. Run "C:\Program Files (x86)\Steam\steamapps\common\Don't Starve Mod Tools\mod_tools\autocompiler.exe"
4. A zip folder with your animation files will be created and copied under `exported` and under `anim`. This folder is created during the process if it doesn't already exist under `<yourmod>/anim`
## FAQ
1. Folder does not contain an anim.bin file\
To create an anim.xml file (which DST Mod Tools creates which is needed to make anim.bin), your scml file needs an `mainline` and `timeline` XML animation node.