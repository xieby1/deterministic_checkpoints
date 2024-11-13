from pydot import Dot, Edge, Node, Graph, Cluster
class CCluster(Cluster): # Connectable Cluster
  def __init__(self, *args, **kwargs):
    Cluster.__init__(self, *args, **kwargs)
    self._connect_node_ = addNode(self, "_connect_node_", label="",
                                  shape="none", width=0, height=0, margin=0)

def addNode(g: Graph|CCluster, name, **args):
  if "label" not in args: args["label"] = name
  n = Node(g.get_name()+name, **args)
  g.add_node(n)
  return n
def addEdge(g: Graph, n1: Node|CCluster, n2: Node|CCluster, **args):
  if isinstance(n1, CCluster): l = n1._connect_node_; args["ltail"] = n1.get_name()
  else: l = n1
  if isinstance(n2, CCluster): r = n2._connect_node_; args["lhead"] = n2.get_name()
  else: r = n2
  g.add_edge(Edge(l.get_name(), r.get_name(), **args))
def addCluster(g: Graph|CCluster, name, **args):
  if "label" not in args: args["label"] = name
  s=CCluster(g.get_name()+name, **args)
  g.add_subgraph(s)
  return s
def add(g: Graph, item: Node|Edge|Graph):
  if   isinstance(item, Node):     g.add_node(item)
  elif isinstance(item, Edge):     g.add_edge(item)
  elif isinstance(item, CCluster): g.add_subgraph(item)
  return item
def Cluster_init(self, name, **args):
  # args["cluster"] = True
  if "label" not in args: args["label"] = name
  CCluster.__init__(self, name, **args)

graph = Dot(label="Deterministic Checkpoint Dependency Graph", bgcolor="transparent", splines="line", compound=True)
graph.set_node_defaults(shape="box")
graph.set_edge_defaults(color="#00000044")


riscv64_cc = addNode(graph, "riscv64-cc")
riscv64_libc_static = addNode(graph, "riscv64-libc-static")
riscv64_fortran = addNode(graph, "riscv64-fortran")
riscv64_jemalloc = addNode(graph, "riscv64-jemalloc")

spec2006 = addCluster(graph, "spec2006", cluster=True)
checkpoints = addNode(graph, "checkpoints")

openblas = addNode(graph, "openblas")
checkpoints_openblas = addNode(graph, "checkpoints-openblas")

class ImgBuilder(CCluster):
  class GCPT(CCluster):
    class OpenSBI(CCluster):
      class Linux(CCluster):
        class InitRamFs(CCluster):
          class Base(CCluster):
            def __init__(self, **args):
              Cluster_init(self, "base", **args)
              self.gen_init_cpio = addNode(self, "gen_init_cpio")
              self.cpio_list = addNode(self, "cpio_list")
          class Overlays(CCluster):
            def __init__(self, **args):
              Cluster_init(self, "overlays", **args)
              self.before_workload = addNode(self, "before_workload")
              self.qemu_trap = addNode(self, "qemu_trap")
              self.nemu_trap = addNode(self, "nemu_trap")
              self.inittab = addNode(self, "inittab")
              self.run_sh = addNode(self, "run_sh", label="run.sh")
          def __init__(self, **args):
            Cluster_init(self, "initramfs", **args)
            self.base = self.Base(); add(self, self.base)
            self.overlays = self.Overlays(); add(self, self.overlays)
        def __init__(self, **args):
          Cluster_init(self, "linux", **args)
          self.initramfs = self.InitRamFs(); add(self, self.initramfs)
          self.common_build = addNode(self, "common-build")
      def __init__(self, **args):
        Cluster_init(self, "opensbi", **args)
        self.dts = addNode(self, "dts")
        self.common_build = addNode(self, "common-build")
        addEdge(self, self.dts, self.common_build)
        self.linux = self.Linux(); add(self, self.linux)
    def __init__(self, **args):
      Cluster_init(self, "gcpt", **args)
      self.opensbi = self.OpenSBI(); add(self, self.opensbi)
  def __init__(self, **args):
    Cluster_init(self, "imgBuilder", **args)
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
imgBuilder = ImgBuilder(); add(graph, imgBuilder)

pkgs = addNode(graph, "pkgs")
addEdge(graph, pkgs, imgBuilder.riscv64_cc)
addEdge(graph, pkgs, imgBuilder.riscv64_libc_static)
addEdge(graph, pkgs, imgBuilder.riscv64_busybox)

class Benchmark(CCluster):
  def __init__(self, name, **args):
    Cluster_init(self, name, **args)
    self.run = addNode(self, "run")
benchmark = Benchmark("benchmark"); add(graph, benchmark)
addEdge(graph, benchmark.run, imgBuilder.gcpt.opensbi.linux.initramfs.overlays.run_sh)
addEdge(graph, benchmark, imgBuilder.gcpt.opensbi.linux.initramfs)

graph.write(__file__.replace("_dot.py", "_py.dot"))
