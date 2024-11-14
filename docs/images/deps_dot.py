from pydot import Dot, Edge, Node, Graph, Cluster
def safe_set(args: dict, key: str, value):
  if key not in args: args[key] = value
class CCluster(Cluster): # Connectable Cluster
  def __init__(self, name, **args):
    safe_set(args, "label", name)
    safe_set(args, "penwidth", 2)
    Cluster.__init__(self, name, **args)
    self._connect_node_ = addNode(self, "_connect_node_", label="",
                                  shape="none", width=0, height=0, margin=0)

def addNode(g: Graph|CCluster, name, **args):
  if "label" not in args: args["label"] = name
  n = Node(g.get_name()+name, **args)
  g.add_node(n)
  return n
def addEdge(g: Graph, n1: Node|CCluster, n2: Node|CCluster, **args):
  # auto edge color
  if isinstance(n1, Node)  and n1.get("color"):    safe_set(args, "color", n1.get("color"))
  if isinstance(n1, Graph) and n1.get("pencolor"): safe_set(args, "color", n1.get("pencolor"))
  # auto edge width
  if n1.get("penwidth"): safe_set(args, "penwidth", n1.get("penwidth"))

  if isinstance(n1, CCluster): l = n1._connect_node_; args["ltail"] = n1.get_name()
  else: l = n1
  if isinstance(n2, CCluster): r = n2._connect_node_; args["lhead"] = n2.get_name()
  else: r = n2
  g.add_edge(Edge(l.get_name(), r.get_name(), **args))
def addCluster(g: Graph|CCluster, name, **args):
  s=CCluster(name, **args)
  g.add_subgraph(s)
  return s
def add(g: Graph, item: Node|Edge|Graph):
  if   isinstance(item, Node):     g.add_node(item)
  elif isinstance(item, Edge):     g.add_edge(item)
  elif isinstance(item, CCluster): g.add_subgraph(item)
  return item

graph = Dot(label="Deterministic Checkpoint Dependency Graph", bgcolor="transparent", splines="line", compound=True)
graph.set_node_defaults(shape="box")
graph.set_edge_defaults(color="#00000044")


class ImgBuilder(CCluster):
  class GCPT(CCluster):
    class OpenSBI(CCluster):
      class Linux(CCluster):
        class InitRamFs(CCluster):
          class Base(CCluster):
            def __init__(self, **args):
              CCluster.__init__(self, "base", **args)
              self.gen_init_cpio = addNode(self, "gen_init_cpio")
              self.cpio_list = addNode(self, "cpio_list")
          class Overlays(CCluster):
            def __init__(self, **args):
              CCluster.__init__(self, "overlays", **args)
              self.before_workload = addNode(self, "before_workload")
              self.qemu_trap = addNode(self, "qemu_trap")
              self.nemu_trap = addNode(self, "nemu_trap")
              self.inittab = addNode(self, "inittab")
              self.run_sh = addNode(self, "run_sh", label="run.sh")
          def __init__(self, **args):
            CCluster.__init__(self, "initramfs", **args)
            self.base = self.Base(); add(self, self.base)
            self.overlays = self.Overlays(); add(self, self.overlays)
        def __init__(self, **args):
          CCluster.__init__(self, "linux", **args)
          self.initramfs = self.InitRamFs(); add(self, self.initramfs)
          self.common_build = addNode(self, "common-build")
      def __init__(self, **args):
        CCluster.__init__(self, "opensbi", **args)
        self.dts = addNode(self, "dts")
        self.common_build = addNode(self, "common-build")
        addEdge(self, self.dts, self.common_build)
        self.linux = self.Linux(); add(self, self.linux)
    def __init__(self, **args):
      CCluster.__init__(self, "gcpt", **args, bgcolor="#DAE8FC", pencolor="#6C8EBF", penwidth=3)
      self.opensbi = self.OpenSBI(); add(self, self.opensbi)
  def __init__(self, **args):
    CCluster.__init__(self, "imgBuilder", **args, bgcolor="#CCE5FF", pencolor="#666666")
    self.riscv64_cc = addNode(self, "riscv64-cc")
    self.riscv64_libc_static = addNode(self, "riscv64-libc-static")
    self.riscv64_busybox = addNode(self, "riscv64-busybox")
    self.gcpt = self.GCPT(); add(self, self.gcpt)
    addEdge(self, self.riscv64_cc, self.gcpt.opensbi.common_build)
    addEdge(self, self.riscv64_cc, self.gcpt.opensbi.linux.common_build)
    for i in (self.riscv64_cc, self.riscv64_libc_static):
      overlays = self.gcpt.opensbi.linux.initramfs.overlays
      for j in (overlays.before_workload, overlays.qemu_trap, overlays.nemu_trap):
        addEdge(self, i, j)
    addEdge(self, self.riscv64_busybox, self.gcpt.opensbi.linux.initramfs.overlays)

class CptBuilder(CCluster):
  def __init__(self, **args):
    CCluster.__init__(self, "cptBuilder", **args, bgcolor="#F8CECC", pencolor="#B85450")
    self.riscv64_cc = addNode(self, "riscv64-cc")
    self.qemu = addNode(self, "qemu")
    self.nemu = addNode(self, "nemu")
    self.stage1_profiling = addNode(self, "stage1_profiling")
    self.simpoint = addNode(self, "simpoint")
    self.stage2_cluster = addNode(self, "stage2_cluster")
    self.stage3_checkpoint = addNode(self, "stage3_checkpoint")
    addEdge(self, self.riscv64_cc, self.nemu)
    addEdge(self, self.qemu, self.stage1_profiling)
    addEdge(self, self.nemu, self.stage1_profiling)
    addEdge(self, self.simpoint, self.stage2_cluster)
    addEdge(self, self.stage1_profiling, self.stage2_cluster)
    addEdge(self, self.qemu, self.stage3_checkpoint)
    addEdge(self, self.nemu, self.stage3_checkpoint)
    addEdge(self, self.stage2_cluster,self.stage3_checkpoint)

class Builder(CCluster):
  def __init__(self, **args):
    CCluster.__init__(self, "builder", **args, bgcolor="#F5F5F5", pencolor="#666666")
    self.imgBuilder = ImgBuilder(); add(self, self.imgBuilder)
    self.cptBuilder = CptBuilder(); add(self, self.cptBuilder)
    addEdge(self, self.imgBuilder.gcpt, self.cptBuilder.stage1_profiling, penwidth=3)
    addEdge(self, self.imgBuilder.gcpt, self.cptBuilder.stage3_checkpoint, penwidth=3)
builder = Builder(); add(graph, builder)

inputs = CCluster("inputs", label="", pencolor="transparent"); add(graph, inputs)
outputs = CCluster("outputs", label="", pencolor="transparent"); add(graph, outputs)

pkgs = addNode(inputs, "pkgs")
addEdge(graph, pkgs, builder.imgBuilder.riscv64_cc)
addEdge(graph, pkgs, builder.imgBuilder.riscv64_libc_static)
addEdge(graph, pkgs, builder.imgBuilder.riscv64_busybox)
addEdge(graph, pkgs, builder.cptBuilder.riscv64_cc)

class Benchmark(CCluster):
  def __init__(self, name, **args):
    CCluster.__init__(self, name, **args, bgcolor="#D5E8D4", pencolor="#82B366")
    self.run = addNode(self, "run")
benchmark = Benchmark("benchmark"); add(inputs, benchmark)
addEdge(graph, benchmark.run, builder.imgBuilder.gcpt.opensbi.linux.initramfs.overlays.run_sh)
addEdge(graph, benchmark, builder.imgBuilder.gcpt.opensbi.linux.initramfs)

checkpoints = addNode(graph, "checkpoints", style="filled", fillcolor="#FFE6CC", color="#D79B00")
addEdge(outputs, builder.cptBuilder.stage3_checkpoint, checkpoints)

# Tweaks
addEdge(graph, builder.imgBuilder.gcpt.opensbi.common_build, builder.cptBuilder.riscv64_cc, color="transparent")

graph.write(__file__.replace("_dot.py", "_py.dot"))
