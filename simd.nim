#
#
#                Nim's SIMD DSL
#        (c) Copyright 2014 Ben Segovia
#
#    See the file copying.txt, included in this
#    distribution, for details about the copyright.
#
import macros
import x86_sse
import x86_sse2

######################################################
# Wrap SIMD SSE Boolean type
######################################################
type
  sseb {.byref.} = object
    vector: m128

proc `!`*(x: sseb): sseb {.inline.} =
  sseb(vector: xor_ps(x.vector, set1_ps(cast[float32](0xffffffff))))

proc any*(x: sseb): bool {.inline.} =
  0 != movemask_ps(x.vector)

######################################################
# Wrap SIMD SSE FP32 type
######################################################
type
  ssef {.byref.} = object
    vector: m128

proc ssefv*(x: float32): ssef {.inline.} =
  ssef(vector: set1_ps(x))

proc ssefv*(x: m128): ssef {.inline.} =
  ssef(vector: x)

proc `+`*(x: ssef, y: ssef): ssef {.inline.} =
  ssef(vector: add_ps(x.vector, y.vector))

proc `-`*(x: ssef, y: ssef): ssef {.inline.} =
  ssef(vector: sub_ps(x.vector, y.vector))
proc `-`*(x: ssef, y: float32): ssef {.inline.} =
  ssef(vector: sub_ps(x.vector, set1_ps(y)))

proc `*`*(x: ssef, y: ssef): ssef {.inline.} =
  ssef(vector: mul_ps(x.vector, y.vector))

proc `/`*(x: ssef, y: ssef): ssef {.inline.} =
  ssef(vector: div_ps(x.vector, y.vector))

proc `==`*(x: ssef, y: ssef): sseb {.inline.} =
  sseb(vector: cmpeq_ps(x.vector, y.vector))

proc `!=`*(x: ssef, y: ssef): sseb {.inline.} =
  sseb(vector: cmpneq_ps(x.vector, y.vector))

proc `<`*(x: ssef, y: ssef): sseb {.inline.} =
  sseb(vector: cmplt_ps(x.vector, y.vector))

proc `<`*(x: ssef, y: float32): sseb {.inline.} =
  sseb(vector: cmplt_ps(x.vector, set1_ps(y)))

proc `>`*(x: ssef, y: ssef): sseb {.inline.} =
  sseb(vector: cmpgt_ps(x.vector, y.vector))

proc `<=`*(x: ssef, y: ssef): sseb {.inline.} =
  sseb(vector: cmple_ps(x.vector, y.vector))

proc `>=`*(x: ssef, y: ssef): sseb {.inline.} =
  sseb(vector: cmpge_ps(x.vector, y.vector))
proc `>=`*(x: ssef, y: float32): sseb {.inline.} =
  sseb(vector: cmpge_ps(x.vector, set1_ps(y)))
proc `>=`*(x: float32, y: ssef): sseb {.inline.} =
  sseb(vector: cmpge_ps(set1_ps(x), y.vector))

######################################################
# Wrap SIMD SSE int32 type
######################################################
type
  ssei {.byref.} = object
    vector: m128i

proc `<`*(x: ssei, y: ssei): sseb {.inline.} =
  sseb(vector: castsi128_ps(cmplt_epi32(x.vector, y.vector)))

proc `>`*(x: ssei, y: ssei): sseb {.inline.} =
  sseb(vector: castsi128_ps(cmpgt_epi32(x.vector, y.vector)))

######################################################
# Boiler plate to vectorize a statement
######################################################
proc any*(x: bool): bool {.inline.} = x

proc process(n: PNimrodNode): PNimrodNode {.compileTime.}

proc processStmtList(n: PNimrodNode): PNimrodNode {.compileTime.} =
  result = newNimNode(nnkStmtList)
  for i in countup(0,n.len()-1):
    result.add process(n[i])

proc processIfStmt(n: PNimrodNode): PNimrodNode {.compileTime.} =
  result = newNimNode(nnkIfStmt)
  for i in countup(0,n.len()-1):
    result.add process(n[i])

proc processAssignment(n: PNimrodNode): PNimrodNode {.compileTime.} =
  result = newNimNode(nnkIfStmt)
  for i in countup(0,n.len()-1):
    result.add process(n[i])

proc processElifBranch(n: PNimrodNode): PNimrodNode {.compileTime.} =
  result = newNimNode(nnkElifBranch)
  result.add newCall("any", n[0])
  for i in countup(1,n.len()-1):
    result.add process(n[i])

proc process(n: PNimrodNode): PNimrodNode =
  case n.kind
  of nnkStmtList: result = processStmtList(n)
  of nnkIfStmt: result = processIfStmt(n)
  of nnkElifBranch: result = processElifBranch(n)
  else: result = n

macro simd(n: stmt): stmt {.immediate.} =
  echo n.treeRepr
  var newNode = process(n)
  echo newNode.treeRepr
  newNode

dumpTree:
  type
    sse3f {.byref.} = object
      x,y,z:ssef

simd:
  var i = ssefv(256.0)
  if i >= 0.0:
    i = i - 1.0

