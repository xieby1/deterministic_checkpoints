import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from table_common import gen_table
gen_table(
    "https://raw.githubusercontent.com/OpenXiangShan/Deterload/refs/heads/data/openblas.txt",
    Path(__file__).with_suffix(".html")
)
