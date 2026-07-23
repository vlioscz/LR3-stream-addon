# Brand assets

The source design for the LR3 Stream add-on's icon and logo — a red **LR3**
wordmark with **vlios.cz** beneath, on grey shutter slats. Same visual style as
the IS3 Export integration.

| File | Size |
| --- | --- |
| `icon.png` | 256×256 |
| `icon@2x.png` | 512×512 |
| `logo.png` | 461×256 |
| `logo@2x.png` | 922×512 |

`icon.svg` is the source; `make_icons.py` renders the PNGs from the same design
(run it from the repository root with Pillow installed). The script also copies
`icon.png` and `logo.png` into `../lr3_stream/`, where Home Assistant reads the
add-on's icon and logo for the Add-on Store.

```bash
python brands/make_icons.py
```

Colours: red `#e2001a`, grey `#9a9a9a`. Font: Arial Black.
