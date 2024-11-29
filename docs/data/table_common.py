from pathlib import Path
import re
import pandas as pd
import plotly.graph_objects as go

def gen_table(csv_url: str, output: Path) -> None:
  df = pd.read_csv(csv_url, header=None)
  df = df.drop(columns=df.columns[-1]) # drop last null column, introduced by the tail comma
  
  header=df.iloc[0].map(lambda s: (re.findall(r'[0-9]+\.[^\.]+', str(s))+[str(s)])[0])
  header = [s[0:3] for s in header]
  header[0]="Date"; header[1]="Commit"; header[2]="All"
  
  def hash_color(s: str) -> str:
    h = hash(s)
    return f"rgb({h&0xff},{(h>>8)&0xff},{(h>>16)&0xff})"
  colors = df.map(lambda e: hash_color(str(e)))
  colors[0]="lightgray"
  colors = colors.transpose()
  
  cells = df.map(lambda s: str(s).replace("/nix/store/", ""))
  cells = cells.transpose()
  
  fig = go.Figure(
    data=[go.Table(
      header=dict(values=header),
      cells=dict(
        values = cells,
        fill_color = colors,
        align = "left",
      ),
    )]
  )
  
  # https://stackoverflow.com/questions/29968152/setting-background-color-to-transparent-in-plotly-plots
  fig.update_layout(
      template="plotly_white",
      paper_bgcolor="rgba(0,0,0,0)",
      plot_bgcolor="rgba(0,0,0,0)",
  )
  fig.write_html(
      output,
      full_html=False,
  )
