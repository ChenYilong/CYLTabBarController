
var Rive = (() => {
  var _scriptName = typeof document != 'undefined' ? document.currentScript?.src : undefined;

  return (
function(moduleArg = {}) {
  var document = moduleArg.document;
  var navigator = moduleArg.navigator;
  var performance = moduleArg.performance || {
    now: function() { return Date.now(); },
    mark: function() {},
    measure: function() {},
    clearMarks: function() {},
    clearMeasures: function() {}
  };
  var requestAnimationFrame = moduleArg.requestAnimationFrame;
  var cancelAnimationFrame = moduleArg.cancelAnimationFrame;
  var Path2D = moduleArg.Path2D;
  var DOMMatrix = moduleArg.DOMMatrix;
  var Image = moduleArg.Image;
  var Blob = moduleArg.Blob;
  var URL = moduleArg.URL;
  var moduleRtn;

var k = moduleArg, ba, ca, da = new Promise((a, b) => {
  ba = a;
  ca = b;
}), ea = "object" == typeof window, ha = "function" == typeof importScripts;
function ia() {
  function a(g) {
    const h = d;
    c = b = 0;
    d = new Map();
    h.forEach(n => {
      try {
        n(g);
      } catch (m) {
        console.error(m);
      }
    });
    this.gb();
    e && e.Hb();
  }
  let b = 0, c = 0, d = new Map(), e = null, f = null;
  this.requestAnimationFrame = function(g) {
    b ||= requestAnimationFrame(a.bind(this));
    const h = ++c;
    d.set(h, g);
    return h;
  };
  this.cancelAnimationFrame = function(g) {
    d.delete(g);
    b && 0 == d.size && (cancelAnimationFrame(b), b = 0);
  };
  this.Fb = function(g) {
    f && (document.body.remove(f), f = null);
    g || (f = document.createElement("div"), f.style.backgroundColor = "black", f.style.position = "fixed", f.style.right = 0, f.style.top = 0, f.style.color = "white", f.style.padding = "4px", f.innerHTML = "RIVE FPS", g = function(h) {
      f.innerHTML = "RIVE FPS " + h.toFixed(1);
    }, document.body.appendChild(f));
    e = new function() {
      let h = 0, n = 0;
      this.Hb = function() {
        var m = performance.now();
        n ? (++h, m -= n, 1000 < m && (g(1000 * h / m), h = n = 0)) : (n = m, h = 0);
      };
    }();
  };
  this.Cb = function() {
    f && (document.body.remove(f), f = null);
    e = null;
  };
  this.gb = function() {
  };
}
function ja(a) {
  console.assert(!0);
  const b = new Map();
  let c = -Infinity;
  this.push = function(d) {
    d = d + ((1 << a) - 1) >> a;
    b.has(d) && clearTimeout(b.get(d));
    b.set(d, setTimeout(function() {
      b.delete(d);
      0 == b.length ? c = -Infinity : d == c && (c = Math.max(...b.keys()), console.assert(c < d));
    }, 1000));
    c = Math.max(d, c);
    return c << a;
  };
}
const ka = k.onRuntimeInitialized;
k.onRuntimeInitialized = function() {
  ka && ka();
  let a = k.decodeAudio;
  k.decodeAudio = function(f, g) {
    f = a(f);
    g(f);
  };
  let b = k.decodeFont;
  k.decodeFont = function(f, g) {
    f = b(f);
    g(f);
  };
  let c = k.setFallbackFontCb;
  k.setFallbackFontCallback = "function" === typeof c ? function(f) {
    c(f);
  } : function() {
    console.warn("Module.setFallbackFontCallback called, but text support is not enabled in this build.");
  };
  const d = k.FileAssetLoader;
  k.ptrToAsset = f => {
    let g = k.ptrToFileAsset(f);
    return g.isImage ? k.ptrToImageAsset(f) : g.isFont ? k.ptrToFontAsset(f) : g.isAudio ? k.ptrToAudioAsset(f) : g;
  };
  k.CustomFileAssetLoader = d.extend("CustomFileAssetLoader", {__construct:function({loadContents:f}) {
    this.__parent.__construct.call(this);
    this.ub = f;
  }, loadContents:function(f, g) {
    f = k.ptrToAsset(f);
    return this.ub(f, g);
  },});
  k.CDNFileAssetLoader = d.extend("CDNFileAssetLoader", {__construct:function() {
    this.__parent.__construct.call(this);
  }, loadContents:function(f) {
    let g = k.ptrToAsset(f);
    f = g.cdnUuid;
    if ("" === f) {
      return !1;
    }
    (function(h, n) {
      var m = new XMLHttpRequest();
      m.responseType = "arraybuffer";
      m.onreadystatechange = function() {
        4 == m.readyState && 200 == m.status && n(m);
      };
      m.open("GET", h, !0);
      m.send(null);
    })(g.cdnBaseUrl + "/" + f, h => {
      g.decode(new Uint8Array(h.response));
    });
    return !0;
  },});
  k.FallbackFileAssetLoader = d.extend("FallbackFileAssetLoader", {__construct:function() {
    this.__parent.__construct.call(this);
    this.bb = [];
  }, addLoader:function(f) {
    this.bb.push(f);
  }, loadContents:function(f, g) {
    for (let h of this.bb) {
      if (h.loadContents(f, g)) {
        return !0;
      }
    }
    return !1;
  },});
  let e = k.computeAlignment;
  k.computeAlignment = function(f, g, h, n, m = 1.0) {
    return e.call(this, f, g, h, n, m);
  };
};
const la = "createConicGradient createImageData createLinearGradient createPattern createRadialGradient getContextAttributes getImageData getLineDash getTransform isContextLost isPointInPath isPointInStroke measureText".split(" "), ma = new function() {
  function a() {
    if (!b) {
      var l = document.createElement("canvas"), t = {alpha:1, depth:0, stencil:0, antialias:0, premultipliedAlpha:1, preserveDrawingBuffer:0, powerPreference:"high-performance", failIfMajorPerformanceCaveat:0, enableExtensionsByDefault:1, explicitSwapControl:1, renderViaOffscreenBackBuffer:1,};
      let q;
      if (/iPhone|iPad|iPod/i.test(navigator.userAgent)) {
        if (q = l.getContext("webgl", t), c = 1, !q) {
          return console.log("No WebGL support. Image mesh will not be drawn."), !1;
        }
      } else {
        if (q = l.getContext("webgl2", t)) {
          c = 2;
        } else {
          if (q = l.getContext("webgl", t)) {
            c = 1;
          } else {
            return console.log("No WebGL support. Image mesh will not be drawn."), !1;
          }
        }
      }
      q = new Proxy(q, {get(H, v) {
        if (H.isContextLost()) {
          if (n || (console.error("Cannot render the mesh because the GL Context was lost. Tried to invoke ", v), n = !0), "function" === typeof H[v]) {
            return function() {
            };
          }
        } else {
          return "function" === typeof H[v] ? function(...K) {
            return H[v].apply(H, K);
          } : H[v];
        }
      }, set(H, v, K) {
        if (H.isContextLost()) {
          n || (console.error("Cannot render the mesh because the GL Context was lost. Tried to set property " + v), n = !0);
        } else {
          return H[v] = K, !0;
        }
      },});
      d = Math.min(q.getParameter(q.MAX_RENDERBUFFER_SIZE), q.getParameter(q.MAX_TEXTURE_SIZE));
      function C(H, v, K) {
        v = q.createShader(v);
        q.shaderSource(v, K);
        q.compileShader(v);
        K = q.getShaderInfoLog(v);
        if (0 < (K || "").length) {
          throw K;
        }
        q.attachShader(H, v);
      }
      l = q.createProgram();
      C(l, q.VERTEX_SHADER, "attribute vec2 vertex;\n                attribute vec2 uv;\n                uniform vec4 mat;\n                uniform vec2 translate;\n                varying vec2 st;\n                void main() {\n                    st = uv;\n                    gl_Position = vec4(mat2(mat) * vertex + translate, 0, 1);\n                }");
      C(l, q.FRAGMENT_SHADER, "precision highp float;\n                uniform sampler2D image;\n                varying vec2 st;\n                void main() {\n                    gl_FragColor = texture2D(image, st);\n                }");
      q.bindAttribLocation(l, 0, "vertex");
      q.bindAttribLocation(l, 1, "uv");
      q.linkProgram(l);
      t = q.getProgramInfoLog(l);
      if (0 < (t || "").trim().length) {
        throw t;
      }
      e = q.getUniformLocation(l, "mat");
      f = q.getUniformLocation(l, "translate");
      q.useProgram(l);
      q.bindBuffer(q.ARRAY_BUFFER, q.createBuffer());
      q.enableVertexAttribArray(0);
      q.enableVertexAttribArray(1);
      q.bindBuffer(q.ELEMENT_ARRAY_BUFFER, q.createBuffer());
      q.uniform1i(q.getUniformLocation(l, "image"), 0);
      q.pixelStorei(q.UNPACK_PREMULTIPLY_ALPHA_WEBGL, !0);
      b = q;
    }
    return !0;
  }
  let b = null, c = 0, d = 0, e = null, f = null, g = 0, h = 0, n = !1;
  a();
  this.Tb = function() {
    a();
    return d;
  };
  this.Bb = function(l) {
    b.deleteTexture && b.deleteTexture(l);
  };
  this.Ab = function(l) {
    if (!a()) {
      return null;
    }
    const t = b.createTexture();
    if (!t) {
      return null;
    }
    b.bindTexture(b.TEXTURE_2D, t);
    b.texImage2D(b.TEXTURE_2D, 0, b.RGBA, b.RGBA, b.UNSIGNED_BYTE, l);
    b.texParameteri(b.TEXTURE_2D, b.TEXTURE_WRAP_S, b.CLAMP_TO_EDGE);
    b.texParameteri(b.TEXTURE_2D, b.TEXTURE_WRAP_T, b.CLAMP_TO_EDGE);
    b.texParameteri(b.TEXTURE_2D, b.TEXTURE_MAG_FILTER, b.LINEAR);
    2 == c ? (b.texParameteri(b.TEXTURE_2D, b.TEXTURE_MIN_FILTER, b.LINEAR_MIPMAP_LINEAR), b.generateMipmap(b.TEXTURE_2D)) : b.texParameteri(b.TEXTURE_2D, b.TEXTURE_MIN_FILTER, b.LINEAR);
    return t;
  };
  const m = new ja(8), r = new ja(8), w = new ja(10), x = new ja(10);
  this.Eb = function(l, t, q, C, H) {
    if (a()) {
      var v = m.push(l), K = r.push(t);
      if (b.canvas) {
        if (b.canvas.width != v || b.canvas.height != K) {
          b.canvas.width = v, b.canvas.height = K;
        }
        b.viewport(0, K - t, l, t);
        b.disable(b.SCISSOR_TEST);
        b.clearColor(0, 0, 0, 0);
        b.clear(b.COLOR_BUFFER_BIT);
        b.enable(b.SCISSOR_TEST);
        q.sort((J, Z) => Z.nb - J.nb);
        v = w.push(C);
        g != v && (b.bufferData(b.ARRAY_BUFFER, 8 * v, b.DYNAMIC_DRAW), g = v);
        v = 0;
        for (var Q of q) {
          b.bufferSubData(b.ARRAY_BUFFER, v, Q.La), v += 4 * Q.La.length;
        }
        console.assert(v == 4 * C);
        for (var U of q) {
          b.bufferSubData(b.ARRAY_BUFFER, v, U.rb), v += 4 * U.rb.length;
        }
        console.assert(v == 8 * C);
        v = x.push(H);
        h != v && (b.bufferData(b.ELEMENT_ARRAY_BUFFER, 2 * v, b.DYNAMIC_DRAW), h = v);
        Q = 0;
        for (var pa of q) {
          b.bufferSubData(b.ELEMENT_ARRAY_BUFFER, Q, pa.indices), Q += 2 * pa.indices.length;
        }
        console.assert(Q == 2 * H);
        pa = 0;
        U = !0;
        v = Q = 0;
        for (const J of q) {
          J.image.Da != pa && (b.bindTexture(b.TEXTURE_2D, J.image.Ca || null), pa = J.image.Da);
          J.Yb ? (b.scissor(J.Ra, K - J.Sa - J.ab, J.kc, J.ab), U = !0) : U && (b.scissor(0, K - t, l, t), U = !1);
          q = 2 / l;
          const Z = -2 / t;
          b.uniform4f(e, J.da[0] * q * J.ua, J.da[1] * Z * J.va, J.da[2] * q * J.ua, J.da[3] * Z * J.va);
          b.uniform2f(f, J.da[4] * q * J.ua + q * (J.Ra - J.Ub * J.ua) - 1, J.da[5] * Z * J.va + Z * (J.Sa - J.Vb * J.va) + 1);
          b.vertexAttribPointer(0, 2, b.FLOAT, !1, 0, v);
          b.vertexAttribPointer(1, 2, b.FLOAT, !1, 0, v + 4 * C);
          b.drawElements(b.TRIANGLES, J.indices.length, b.UNSIGNED_SHORT, Q);
          v += 4 * J.La.length;
          Q += 2 * J.indices.length;
        }
        console.assert(v == 4 * C);
        console.assert(Q == 2 * H);
      }
    }
  };
  this.canvas = function() {
    return a() && b.canvas;
  };
}(), na = k.onRuntimeInitialized;
k.onRuntimeInitialized = function() {
  function a(p) {
    switch(p) {
      case m.srcOver:
        return "source-over";
      case m.screen:
        return "screen";
      case m.overlay:
        return "overlay";
      case m.darken:
        return "darken";
      case m.lighten:
        return "lighten";
      case m.colorDodge:
        return "color-dodge";
      case m.colorBurn:
        return "color-burn";
      case m.hardLight:
        return "hard-light";
      case m.softLight:
        return "soft-light";
      case m.difference:
        return "difference";
      case m.exclusion:
        return "exclusion";
      case m.multiply:
        return "multiply";
      case m.hue:
        return "hue";
      case m.saturation:
        return "saturation";
      case m.color:
        return "color";
      case m.luminosity:
        return "luminosity";
    }
  }
  function b(p) {
    return "rgba(" + ((16711680 & p) >>> 16) + "," + ((65280 & p) >>> 8) + "," + ((255 & p) >>> 0) + "," + ((4278190080 & p) >>> 24) / 255 + ")";
  }
  function c() {
    0 < K.length && (ma.Eb(v.drawWidth(), v.drawHeight(), K, Q, U), K = [], U = Q = 0, v.reset(512, 512));
    for (const p of H) {
      for (const u of p.G) {
        u();
      }
      p.G = [];
    }
    H.clear();
  }
  na && na();
  var d = k.RenderPaintStyle;
  const e = k.RenderPath, f = k.RenderPaint, g = k.Renderer, h = k.StrokeCap, n = k.StrokeJoin, m = k.BlendMode, r = d.fill, w = d.stroke, x = k.FillRule.evenOdd;
  let l = 1;
  var t = k.RenderImage.extend("CanvasRenderImage", {__construct:function({ha:p, sa:u} = {}) {
    this.__parent.__construct.call(this);
    this.Da = l;
    l = l + 1 & 2147483647 || 1;
    this.ha = p;
    this.sa = u;
  }, __destruct:function() {
    this.Ca && ma.Bb(this.Ca);
    this.Oa && URL.revokeObjectURL(this.Oa);
    this.__parent.__destruct.call(this);
  }, decode:function(p) {
    var u = this;
    u.sa && u.sa(u);
    var I = new Image();
    u.Oa = URL.createObjectURL(new Blob([p], {type:"image/png",}));
    var completed = !1;
    I.onload = function() {
      if (completed) return;
      completed = !0;
      u.tb = I;
      u.Ca = ma.Ab(I);
      u.size(I.width, I.height);
      u.ha && u.ha(u);
    };
    I.onerror = function() {
      if (completed) return;
      completed = !0;
      console.warn("Rive embedded image decode failed");
      URL.revokeObjectURL(u.Oa);
      u.Oa = "";
      u.ha && u.ha(u);
    };
    I.src = u.Oa;
  },}), q = e.extend("CanvasRenderPath", {__construct:function() {
    this.__parent.__construct.call(this);
    this.R = new Path2D();
  }, rewind:function() {
    this.R = new Path2D();
  }, addPath:function(p, u, I, F, z, G, D) {
    var L = this.R, xa = L.addPath;
    p = p.R;
    const S = new DOMMatrix();
    S.a = u;
    S.b = I;
    S.c = F;
    S.d = z;
    S.e = G;
    S.f = D;
    xa.call(L, p, S);
  }, fillRule:function(p) {
    this.Na = p;
  }, moveTo:function(p, u) {
    this.R.moveTo(p, u);
  }, lineTo:function(p, u) {
    this.R.lineTo(p, u);
  }, cubicTo:function(p, u, I, F, z, G) {
    this.R.bezierCurveTo(p, u, I, F, z, G);
  }, close:function() {
    this.R.closePath();
  },}), C = f.extend("CanvasRenderPaint", {color:function(p) {
    this.Pa = b(p);
  }, thickness:function(p) {
    this.xb = p;
  }, join:function(p) {
    switch(p) {
      case n.miter:
        this.Ba = "miter";
        break;
      case n.round:
        this.Ba = "round";
        break;
      case n.bevel:
        this.Ba = "bevel";
    }
  }, cap:function(p) {
    switch(p) {
      case h.butt:
        this.Aa = "butt";
        break;
      case h.round:
        this.Aa = "round";
        break;
      case h.square:
        this.Aa = "square";
    }
  }, style:function(p) {
    this.wb = p;
  }, blendMode:function(p) {
    this.sb = a(p);
  }, clearGradient:function() {
    this.fa = null;
  }, linearGradient:function(p, u, I, F) {
    this.fa = {ob:p, pb:u, Va:I, Wa:F, Ja:[],};
  }, radialGradient:function(p, u, I, F) {
    this.fa = {ob:p, pb:u, Va:I, Wa:F, Ja:[], Sb:!0,};
  }, addStop:function(p, u) {
    this.fa.Ja.push({color:p, stop:u,});
  }, completeGradient:function() {
  }, draw:function(p, u, I, F) {
    let z = this.wb;
    var G = this.Pa, D = this.fa;
    const L = p.globalCompositeOperation, xa = p.globalAlpha;
    p.globalCompositeOperation = this.sb;
    p.globalAlpha = F;
    if (null != D) {
      G = D.ob;
      const W = D.pb, fa = D.Va;
      var S = D.Wa;
      F = D.Ja;
      D.Sb ? (D = fa - G, S -= W, G = p.createRadialGradient(G, W, 0, G, W, Math.sqrt(D * D + S * S))) : G = p.createLinearGradient(G, W, fa, S);
      for (let X = 0, aa = F.length; X < aa; X++) {
        D = F[X], G.addColorStop(D.stop, b(D.color));
      }
      this.Pa = G;
      this.fa = null;
    }
    switch(z) {
      case w:
        p.strokeStyle = G;
        p.lineWidth = this.xb;
        p.lineCap = this.Aa;
        p.lineJoin = this.Ba;
        p.stroke(u);
        break;
      case r:
        p.fillStyle = G, p.fill(u, I);
    }
    p.globalCompositeOperation = L;
    p.globalAlpha = xa;
  },});
  const H = new Set();
  let v = null, K = [], Q = 0, U = 0;
  var pa = k.CanvasRenderer = g.extend("Renderer", {__construct:function(p) {
    this.__parent.__construct.call(this);
    this.P = [1, 0, 0, 1, 0, 0];
    this.D = [1.0];
    this.A = p.getContext("2d");
    this.Ma = p;
    this.G = [];
  }, save:function() {
    this.P.push(...this.P.slice(this.P.length - 6));
    this.D.push(this.D[this.D.length - 1]);
    this.G.push(this.A.save.bind(this.A));
  }, restore:function() {
    const p = this.P.length - 6;
    if (6 > p) {
      throw "restore() called without matching save().";
    }
    this.P.splice(p);
    this.D.pop();
    this.G.push(this.A.restore.bind(this.A));
  }, transform:function(p, u, I, F, z, G) {
    const D = this.P, L = D.length - 6;
    D.splice(L, 6, D[L] * p + D[L + 2] * u, D[L + 1] * p + D[L + 3] * u, D[L] * I + D[L + 2] * F, D[L + 1] * I + D[L + 3] * F, D[L] * z + D[L + 2] * G + D[L + 4], D[L + 1] * z + D[L + 3] * G + D[L + 5]);
    this.G.push(this.A.transform.bind(this.A, p, u, I, F, z, G));
  }, rotate:function(p) {
    const u = Math.sin(p);
    p = Math.cos(p);
    this.transform(p, u, -u, p, 0, 0);
  }, modulateOpacity:function(p) {
    this.D[this.D.length - 1] *= p;
  }, _drawPath:function(p, u) {
    this.G.push(u.draw.bind(u, this.A, p.R, p.Na === x ? "evenodd" : "nonzero", Math.max(0, this.D[this.D.length - 1])));
  }, _drawRiveImage:function(p, u, I, F) {
    var z = p.tb;
    if (z) {
      var G = this.A, D = a(I), L = Math.max(0, F * this.D[this.D.length - 1]);
      this.G.push(function() {
        G.globalCompositeOperation = D;
        G.globalAlpha = L;
        G.drawImage(z, 0, 0);
        G.globalAlpha = 1;
      });
    }
  }, _getMatrix:function(p) {
    const u = this.P, I = u.length - 6;
    for (let F = 0; 6 > F; ++F) {
      p[F] = u[I + F];
    }
  }, _drawImageMesh:function(p, u, I, F, z, G, D, L, xa, S, W, fa, X, aa) {
    let $b, ac, bc;
    try {
      $b = k.HEAPF32.slice(z >> 2, (z >> 2) + G), ac = k.HEAPF32.slice(D >> 2, (D >> 2) + L), bc = k.HEAPU16.slice(xa >> 1, (xa >> 1) + S);
    } catch (sb) {
      console.error("[Rive] _drawImageMesh: failed to read mesh data from WASM heap. Mesh skipped for this frame.");
      return;
    }
    u = this.A.canvas.width;
    z = this.A.canvas.height;
    D = X - W;
    L = aa - fa;
    W = Math.max(W, 0);
    fa = Math.max(fa, 0);
    X = Math.min(X, u);
    aa = Math.min(aa, z);
    const Fa = X - W, Ga = aa - fa;
    console.assert(Fa <= Math.min(D, u));
    console.assert(Ga <= Math.min(L, z));
    if (!(0 >= Fa || 0 >= Ga)) {
      X = Fa < D || Ga < L;
      u = aa = 1;
      var qa = Math.ceil(Fa * aa), ra = Math.ceil(Ga * u);
      z = ma.Tb();
      qa > z && (aa *= z / qa, qa = z);
      ra > z && (u *= z / ra, ra = z);
      v || (v = new k.DynamicRectanizer(z), v.reset(512, 512));
      z = v.addRect(qa, ra);
      0 > z && (c(), H.add(this), z = v.addRect(qa, ra), console.assert(0 <= z));
      var cc = z & 65535, dc = z >> 16;
      K.push({da:this.P.slice(this.P.length - 6), image:p, Ra:cc, Sa:dc, Ub:W, Vb:fa, kc:qa, ab:ra, ua:aa, va:u, La:$b, rb:ac, indices:bc, Yb:X, nb:p.Da << 1 | (X ? 1 : 0),});
      Q += G;
      U += S;
      var ya = this.A, qd = a(I), rd = Math.max(0, F * this.D[this.D.length - 1]);
      this.G.push(function() {
        ya.save();
        ya.resetTransform();
        ya.globalCompositeOperation = qd;
        ya.globalAlpha = rd;
        const sb = ma.canvas();
        sb && ya.drawImage(sb, cc, dc, qa, ra, W, fa, Fa, Ga);
        ya.restore();
      });
    }
  }, _clipPath:function(p) {
    this.G.push(this.A.clip.bind(this.A, p.R, p.Na === x ? "evenodd" : "nonzero"));
  }, clear:function() {
    H.add(this);
    this.G.push(this.A.clearRect.bind(this.A, 0, 0, this.Ma.width, this.Ma.height));
  }, flush:function() {
  }, translate:function(p, u) {
    this.transform(1, 0, 0, 1, p, u);
  },});
  k.makeRenderer = function(p) {
    const u = new pa(p), I = u.A;
    return new Proxy(u, {get(F, z) {
      if ("function" === typeof F[z]) {
        return function(...G) {
          return F[z].apply(F, G);
        };
      }
      if ("function" === typeof I[z]) {
        if (-1 < la.indexOf(z)) {
          throw Error("RiveException: Method call to '" + z + "()' is not allowed, as the renderer cannot immediately pass through the return                 values of any canvas 2d context methods.");
        }
        return function(...G) {
          u.G.push(I[z].bind(I, ...G));
        };
      }
      return F[z];
    }, set(F, z, G) {
      if (z in I) {
        return u.G.push(() => {
          I[z] = G;
        }), !0;
      }
    },});
  };
  k.decodeImage = function(p, u) {
    (new t({ha:u})).decode(p);
  };
  k.renderFactory = {makeRenderPaint:function() {
    return new C();
  }, makeRenderPath:function() {
    return new q();
  }, makeRenderImage:function() {
    let p = Z;
    return new t({sa:() => {
      p.total++;
    }, ha:() => {
      p.loaded++;
      if (p.loaded === p.total) {
        const u = p.ready;
        u && (u(), p.ready = null);
      }
    },});
  },};
  let J = k.load, Z = null;
  k.load = function(p, u, I = !0) {
    const F = new k.FallbackFileAssetLoader();
    void 0 !== u && F.addLoader(u);
    I && (u = new k.CDNFileAssetLoader(), F.addLoader(u));
    return new Promise(function(z) {
      let G = null;
      Z = {total:0, loaded:0, ready:function() {
        z(G);
      },};
      G = J(p, F);
      0 == Z.total && z(G);
    });
  };
  let sd = k.RendererWrapper.prototype.align;
  k.RendererWrapper.prototype.align = function(p, u, I, F, z = 1.0) {
    sd.call(this, p, u, I, F, z);
  };
  d = new ia();
  k.requestAnimationFrame = d.requestAnimationFrame.bind(d);
  k.cancelAnimationFrame = d.cancelAnimationFrame.bind(d);
  k.enableFPSCounter = d.Fb.bind(d);
  k.disableFPSCounter = d.Cb;
  d.gb = c;
  k.resolveAnimationFrame = c;
  k.cleanup = function() {
    v && v.delete();
  };
};
var oa = Object.assign({}, k), sa = "./this.program", ta = "", ua, va;
if (ea || ha) {
  ha ? ta = self.location.href : "undefined" != typeof document && document.currentScript && (ta = document.currentScript.src), _scriptName && (ta = _scriptName), ta.startsWith("blob:") ? ta = "" : ta = ta.substr(0, ta.replace(/[?#].*/, "").lastIndexOf("/") + 1), ha && (va = a => {
    var b = new XMLHttpRequest();
    b.open("GET", a, !1);
    b.responseType = "arraybuffer";
    b.send(null);
    return new Uint8Array(b.response);
  }), ua = (a, b, c) => {
    if (wa(a)) {
      var d = new XMLHttpRequest();
      d.open("GET", a, !0);
      d.responseType = "arraybuffer";
      d.onload = () => {
        200 == d.status || 0 == d.status && d.response ? b(d.response) : c();
      };
      d.onerror = c;
      d.send(null);
    } else {
      fetch(a, {credentials:"same-origin"}).then(e => e.ok ? e.arrayBuffer() : Promise.reject(Error(e.status + " : " + e.url))).then(b, c);
    }
  };
}
var za = k.print || console.log.bind(console), Aa = k.printErr || console.error.bind(console);
Object.assign(k, oa);
oa = null;
k.thisProgram && (sa = k.thisProgram);
var Ba;
k.wasmBinary && (Ba = k.wasmBinary);
var Ca, Da = !1, y, A, Ea, Ha, B, E, Ia, Ja;
function Ka() {
  var a = Ca.buffer;
  k.HEAP8 = y = new Int8Array(a);
  k.HEAP16 = Ea = new Int16Array(a);
  k.HEAPU8 = A = new Uint8Array(a);
  k.HEAPU16 = Ha = new Uint16Array(a);
  k.HEAP32 = B = new Int32Array(a);
  k.HEAPU32 = E = new Uint32Array(a);
  k.HEAPF32 = Ia = new Float32Array(a);
  k.HEAPF64 = Ja = new Float64Array(a);
}
var La = [], Ma = [], Na = [];
function Oa() {
  var a = k.preRun.shift();
  La.unshift(a);
}
var Pa = 0, Qa = null, Ra = null;
function Sa(a) {
  k.onAbort?.(a);
  a = "Aborted(" + a + ")";
  Aa(a);
  Da = !0;
  a = new WebAssembly.RuntimeError(a + ". Build with -sASSERTIONS for more info.");
  ca(a);
  throw a;
}
var Ta = a => a.startsWith("data:application/octet-stream;base64,"), wa = a => a.startsWith("file://"), Ua;
function Va(a) {
  if (a == Ua && Ba) {
    return new Uint8Array(Ba);
  }
  if (va) {
    return va(a);
  }
  throw "both async and sync fetching of the wasm failed";
}
function Wa(a) {
  return Ba ? Promise.resolve().then(() => Va(a)) : new Promise((b, c) => {
    ua(a, d => b(new Uint8Array(d)), () => {
      try {
        b(Va(a));
      } catch (d) {
        c(d);
      }
    });
  });
}
function Xa(a, b, c) {
  return Wa(a).then(d => WebAssembly.instantiate(d, b)).then(c, d => {
    Aa(`failed to asynchronously prepare wasm: ${d}`);
    Sa(d);
  });
}
function Ya(a, b) {
  var c = Ua;
  return Ba || "function" != typeof WebAssembly.instantiateStreaming || Ta(c) || wa(c) || "function" != typeof fetch ? Xa(c, a, b) : fetch(c, {credentials:"same-origin"}).then(d => WebAssembly.instantiateStreaming(d, a).then(b, function(e) {
    Aa(`wasm streaming compile failed: ${e}`);
    Aa("falling back to ArrayBuffer instantiation");
    return Xa(c, a, b);
  }));
}
var Za, $a, db = {487293:(a, b, c, d, e) => {
  if (!moduleArg.audioWindow || void 0 === (moduleArg.audioWindow.AudioContext || moduleArg.audioWindow.webkitAudioContext)) {
    return 0;
  }
  if ("undefined" === typeof moduleArg.audioWindow.miniaudio) {
    moduleArg.audioWindow.miniaudio = {referenceCount:0};
    moduleArg.audioWindow.miniaudio.device_type = {};
    moduleArg.audioWindow.miniaudio.device_type.playback = a;
    moduleArg.audioWindow.miniaudio.device_type.capture = b;
    moduleArg.audioWindow.miniaudio.device_type.duplex = c;
    moduleArg.audioWindow.miniaudio.device_state = {};
    moduleArg.audioWindow.miniaudio.device_state.stopped = d;
    moduleArg.audioWindow.miniaudio.device_state.started = e;
    let f = moduleArg.audioWindow.miniaudio;
    f.devices = [];
    f.track_device = function(g) {
      for (var h = 0; h < f.devices.length; ++h) {
        if (null == f.devices[h]) {
          return f.devices[h] = g, h;
        }
      }
      f.devices.push(g);
      return f.devices.length - 1;
    };
    f.untrack_device_by_index = function(g) {
      for (f.devices[g] = null; 0 < f.devices.length;) {
        if (null == f.devices[f.devices.length - 1]) {
          f.devices.pop();
        } else {
          break;
        }
      }
    };
    f.untrack_device = function(g) {
      for (var h = 0; h < f.devices.length; ++h) {
        if (f.devices[h] == g) {
          return f.untrack_device_by_index(h);
        }
      }
    };
    f.get_device_by_index = function(g) {
      return f.devices[g];
    };
    f.unlock_event_types = ["touchend", "click"];
    f.unlock = function() {
      for (var g = 0; g < f.devices.length; ++g) {
        var h = f.devices[g];
        null != h && null != h.I && h.state === f.device_state.started && h.I.resume().then(() => {
          ab(h.hb);
        }, n => {
          console.error("Failed to resume audiocontext", n);
        });
      }
      f.unlock_event_types.map(function(n) {
        document.removeEventListener(n, f.unlock, !0);
      });
    };
    f.unlock_event_types.map(function(g) {
      document.addEventListener(g, f.unlock, !0);
    });
  }
  moduleArg.audioWindow.miniaudio.referenceCount += 1;
  return 1;
}, 489471:() => {
  "undefined" !== typeof moduleArg.audioWindow.miniaudio && (moduleArg.audioWindow.miniaudio.unlock_event_types.map(function(a) {
    document.removeEventListener(a, moduleArg.audioWindow.miniaudio.unlock, !0);
  }), --moduleArg.audioWindow.miniaudio.referenceCount, 0 === moduleArg.audioWindow.miniaudio.referenceCount && delete moduleArg.audioWindow.miniaudio);
}, 489775:() => !1, 489879:() => {
  try {
    var a = new (moduleArg.audioWindow.AudioContext || moduleArg.audioWindow.webkitAudioContext)(), b = a.sampleRate;
    a.close();
    return b;
  } catch (c) {
    return 0;
  }
}, 490050:(a, b, c, d, e, f) => {
  if ("undefined" === typeof moduleArg.audioWindow.miniaudio) {
    return -1;
  }
  var g = {}, h = {};
  a == moduleArg.audioWindow.miniaudio.device_type.playback && 0 != c && (h.sampleRate = c);
  g.I = new (moduleArg.audioWindow.AudioContext || moduleArg.audioWindow.webkitAudioContext)(h);
  g.I.suspend();
  g.state = moduleArg.audioWindow.miniaudio.device_state.stopped;
  c = 0;
  a != moduleArg.audioWindow.miniaudio.device_type.playback && (c = b);
  g.W = g.I.createScriptProcessor(d, c, b);
  g.W.onaudioprocess = function(n) {
    if (null == g.na || 0 == g.na.length) {
      g.na = new Float32Array(Ia.buffer, e, d * b);
    }
    if (a == moduleArg.audioWindow.miniaudio.device_type.capture || a == moduleArg.audioWindow.miniaudio.device_type.duplex) {
      for (var m = 0; m < b; m += 1) {
        for (var r = n.inputBuffer.getChannelData(m), w = g.na, x = 0; x < d; x += 1) {
          w[x * b + m] = r[x];
        }
      }
      bb(f, d, e);
    }
    if (a == moduleArg.audioWindow.miniaudio.device_type.playback || a == moduleArg.audioWindow.miniaudio.device_type.duplex) {
      for (cb(f, d, e), m = 0; m < n.outputBuffer.numberOfChannels; ++m) {
        for (r = n.outputBuffer.getChannelData(m), w = g.na, x = 0; x < d; x += 1) {
          r[x] = w[x * b + m];
        }
      }
    } else {
      for (m = 0; m < n.outputBuffer.numberOfChannels; ++m) {
        n.outputBuffer.getChannelData(m).fill(0.0);
      }
    }
  };
  a != moduleArg.audioWindow.miniaudio.device_type.capture && a != moduleArg.audioWindow.miniaudio.device_type.duplex || Promise.reject(new Error("Audio capture disabled")).then(function(n) {
    g.wa = g.I.createMediaStreamSource(n);
    g.wa.connect(g.W);
    g.W.connect(g.I.destination);
  }).catch(function(n) {
    console.log("Failed to get user media: " + n);
  });
  a == moduleArg.audioWindow.miniaudio.device_type.playback && g.W.connect(g.I.destination);
  g.hb = f;
  return moduleArg.audioWindow.miniaudio.track_device(g);
}, 492927:a => moduleArg.audioWindow.miniaudio.get_device_by_index(a).I.sampleRate, 493E3:a => {
  a = moduleArg.audioWindow.miniaudio.get_device_by_index(a);
  void 0 !== a.W && (a.W.onaudioprocess = function() {
  }, a.W.disconnect(), a.W = void 0);
  void 0 !== a.wa && (a.wa.disconnect(), a.wa = void 0);
  a.I.close();
  a.I = void 0;
  a.hb = void 0;
}, 493400:a => {
  moduleArg.audioWindow.miniaudio.untrack_device_by_index(a);
}, 493450:a => {
  a = moduleArg.audioWindow.miniaudio.get_device_by_index(a);
  a.I.resume();
  a.state = moduleArg.audioWindow.miniaudio.device_state.started;
}, 493589:a => {
  a = moduleArg.audioWindow.miniaudio.get_device_by_index(a);
  a.I.suspend();
  a.state = moduleArg.audioWindow.miniaudio.device_state.stopped;
}}, eb = a => {
  for (; 0 < a.length;) {
    a.shift()(k);
  }
};
function fb() {
  var a = B[+gb >> 2];
  gb += 4;
  return a;
}
var hb = (a, b) => {
  for (var c = 0, d = a.length - 1; 0 <= d; d--) {
    var e = a[d];
    "." === e ? a.splice(d, 1) : ".." === e ? (a.splice(d, 1), c++) : c && (a.splice(d, 1), c--);
  }
  if (b) {
    for (; c; c--) {
      a.unshift("..");
    }
  }
  return a;
}, ib = a => {
  var b = "/" === a.charAt(0), c = "/" === a.substr(-1);
  (a = hb(a.split("/").filter(d => !!d), !b).join("/")) || b || (a = ".");
  a && c && (a += "/");
  return (b ? "/" : "") + a;
}, jb = a => {
  var b = /^(\/?|)([\s\S]*?)((?:\.{1,2}|[^\/]+?|)(\.[^.\/]*|))(?:[\/]*)$/.exec(a).slice(1);
  a = b[0];
  b = b[1];
  if (!a && !b) {
    return ".";
  }
  b &&= b.substr(0, b.length - 1);
  return a + b;
}, kb = a => {
  if ("/" === a) {
    return "/";
  }
  a = ib(a);
  a = a.replace(/\/$/, "");
  var b = a.lastIndexOf("/");
  return -1 === b ? a : a.substr(b + 1);
}, lb = () => {
  if ("object" == typeof crypto && "function" == typeof crypto.getRandomValues) {
    return a => crypto.getRandomValues(a);
  }
  Sa("initRandomDevice");
}, mb = a => (mb = lb())(a), nb = (...a) => {
  for (var b = "", c = !1, d = a.length - 1; -1 <= d && !c; d--) {
    c = 0 <= d ? a[d] : "/";
    if ("string" != typeof c) {
      throw new TypeError("Arguments to path.resolve must be strings");
    }
    if (!c) {
      return "";
    }
    b = c + "/" + b;
    c = "/" === c.charAt(0);
  }
  b = hb(b.split("/").filter(e => !!e), !c).join("/");
  return (c ? "/" : "") + b || ".";
}, ob = "undefined" != typeof TextDecoder ? new TextDecoder("utf8") : void 0, pb = (a, b, c) => {
  var d = b + c;
  for (c = b; a[c] && !(c >= d);) {
    ++c;
  }
  if (16 < c - b && a.buffer && ob) {
    return ob.decode(a.subarray(b, c));
  }
  for (d = ""; b < c;) {
    var e = a[b++];
    if (e & 128) {
      var f = a[b++] & 63;
      if (192 == (e & 224)) {
        d += String.fromCharCode((e & 31) << 6 | f);
      } else {
        var g = a[b++] & 63;
        e = 224 == (e & 240) ? (e & 15) << 12 | f << 6 | g : (e & 7) << 18 | f << 12 | g << 6 | a[b++] & 63;
        65536 > e ? d += String.fromCharCode(e) : (e -= 65536, d += String.fromCharCode(55296 | e >> 10, 56320 | e & 1023));
      }
    } else {
      d += String.fromCharCode(e);
    }
  }
  return d;
}, qb = [], rb = a => {
  for (var b = 0, c = 0; c < a.length; ++c) {
    var d = a.charCodeAt(c);
    127 >= d ? b++ : 2047 >= d ? b += 2 : 55296 <= d && 57343 >= d ? (b += 4, ++c) : b += 3;
  }
  return b;
}, tb = (a, b, c, d) => {
  if (!(0 < d)) {
    return 0;
  }
  var e = c;
  d = c + d - 1;
  for (var f = 0; f < a.length; ++f) {
    var g = a.charCodeAt(f);
    if (55296 <= g && 57343 >= g) {
      var h = a.charCodeAt(++f);
      g = 65536 + ((g & 1023) << 10) | h & 1023;
    }
    if (127 >= g) {
      if (c >= d) {
        break;
      }
      b[c++] = g;
    } else {
      if (2047 >= g) {
        if (c + 1 >= d) {
          break;
        }
        b[c++] = 192 | g >> 6;
      } else {
        if (65535 >= g) {
          if (c + 2 >= d) {
            break;
          }
          b[c++] = 224 | g >> 12;
        } else {
          if (c + 3 >= d) {
            break;
          }
          b[c++] = 240 | g >> 18;
          b[c++] = 128 | g >> 12 & 63;
        }
        b[c++] = 128 | g >> 6 & 63;
      }
      b[c++] = 128 | g & 63;
    }
  }
  b[c] = 0;
  return c - e;
};
function ub(a, b) {
  var c = Array(rb(a) + 1);
  a = tb(a, c, 0, c.length);
  b && (c.length = a);
  return c;
}
var vb = [];
function wb(a, b) {
  vb[a] = {input:[], F:[], T:b};
  xb(a, yb);
}
var yb = {open(a) {
  var b = vb[a.node.ta];
  if (!b) {
    throw new M(43);
  }
  a.o = b;
  a.seekable = !1;
}, close(a) {
  a.o.T.la(a.o);
}, la(a) {
  a.o.T.la(a.o);
}, read(a, b, c, d) {
  if (!a.o || !a.o.T.$a) {
    throw new M(60);
  }
  for (var e = 0, f = 0; f < d; f++) {
    try {
      var g = a.o.T.$a(a.o);
    } catch (h) {
      throw new M(29);
    }
    if (void 0 === g && 0 === e) {
      throw new M(6);
    }
    if (null === g || void 0 === g) {
      break;
    }
    e++;
    b[c + f] = g;
  }
  e && (a.node.timestamp = Date.now());
  return e;
}, write(a, b, c, d) {
  if (!a.o || !a.o.T.Ga) {
    throw new M(60);
  }
  try {
    for (var e = 0; e < d; e++) {
      a.o.T.Ga(a.o, b[c + e]);
    }
  } catch (f) {
    throw new M(29);
  }
  d && (a.node.timestamp = Date.now());
  return e;
},}, zb = {$a() {
  a: {
    if (!qb.length) {
      var a = null;
      "undefined" != typeof window && "function" == typeof window.prompt && (a = window.prompt("Input: "), null !== a && (a += "\n"));
      if (!a) {
        a = null;
        break a;
      }
      qb = ub(a, !0);
    }
    a = qb.shift();
  }
  return a;
}, Ga(a, b) {
  null === b || 10 === b ? (za(pb(a.F, 0)), a.F = []) : 0 != b && a.F.push(b);
}, la(a) {
  a.F && 0 < a.F.length && (za(pb(a.F, 0)), a.F = []);
}, Pb() {
  return {uc:25856, wc:5, tc:191, vc:35387, sc:[3, 28, 127, 21, 4, 0, 1, 0, 17, 19, 26, 0, 18, 15, 23, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,]};
}, Qb() {
  return 0;
}, Rb() {
  return [24, 80];
},}, Ab = {Ga(a, b) {
  null === b || 10 === b ? (Aa(pb(a.F, 0)), a.F = []) : 0 != b && a.F.push(b);
}, la(a) {
  a.F && 0 < a.F.length && (Aa(pb(a.F, 0)), a.F = []);
},};
function Bb(a, b) {
  var c = a.j ? a.j.length : 0;
  c >= b || (b = Math.max(b, c * (1048576 > c ? 2.0 : 1.125) >>> 0), 0 != c && (b = Math.max(b, 256)), c = a.j, a.j = new Uint8Array(b), 0 < a.u && a.j.set(c.subarray(0, a.u), 0));
}
var N = {L:null, S() {
  return N.createNode(null, "/", 16895, 0);
}, createNode(a, b, c, d) {
  if (24576 === (c & 61440) || 4096 === (c & 61440)) {
    throw new M(63);
  }
  N.L || (N.L = {dir:{node:{V:N.i.V, N:N.i.N, ga:N.i.ga, qa:N.i.qa, lb:N.i.lb, qb:N.i.qb, mb:N.i.mb, kb:N.i.kb, xa:N.i.xa}, stream:{Z:N.l.Z}}, file:{node:{V:N.i.V, N:N.i.N}, stream:{Z:N.l.Z, read:N.l.read, write:N.l.write, Qa:N.l.Qa, cb:N.l.cb, fb:N.l.fb}}, link:{node:{V:N.i.V, N:N.i.N, ia:N.i.ia}, stream:{}}, Ta:{node:{V:N.i.V, N:N.i.N}, stream:Cb}});
  c = Db(a, b, c, d);
  16384 === (c.mode & 61440) ? (c.i = N.L.dir.node, c.l = N.L.dir.stream, c.j = {}) : 32768 === (c.mode & 61440) ? (c.i = N.L.file.node, c.l = N.L.file.stream, c.u = 0, c.j = null) : 40960 === (c.mode & 61440) ? (c.i = N.L.link.node, c.l = N.L.link.stream) : 8192 === (c.mode & 61440) && (c.i = N.L.Ta.node, c.l = N.L.Ta.stream);
  c.timestamp = Date.now();
  a && (a.j[b] = c, a.timestamp = c.timestamp);
  return c;
}, Ac(a) {
  return a.j ? a.j.subarray ? a.j.subarray(0, a.u) : new Uint8Array(a.j) : new Uint8Array(0);
}, i:{V(a) {
  var b = {};
  b.yc = 8192 === (a.mode & 61440) ? a.id : 1;
  b.Cc = a.id;
  b.mode = a.mode;
  b.Gc = 1;
  b.uid = 0;
  b.Bc = 0;
  b.ta = a.ta;
  16384 === (a.mode & 61440) ? b.size = 4096 : 32768 === (a.mode & 61440) ? b.size = a.u : 40960 === (a.mode & 61440) ? b.size = a.link.length : b.size = 0;
  b.qc = new Date(a.timestamp);
  b.Fc = new Date(a.timestamp);
  b.xc = new Date(a.timestamp);
  b.yb = 4096;
  b.rc = Math.ceil(b.size / b.yb);
  return b;
}, N(a, b) {
  void 0 !== b.mode && (a.mode = b.mode);
  void 0 !== b.timestamp && (a.timestamp = b.timestamp);
  if (void 0 !== b.size && (b = b.size, a.u != b)) {
    if (0 == b) {
      a.j = null, a.u = 0;
    } else {
      var c = a.j;
      a.j = new Uint8Array(b);
      c && a.j.set(c.subarray(0, Math.min(b, a.u)));
      a.u = b;
    }
  }
}, ga() {
  throw Eb[44];
}, qa(a, b, c, d) {
  return N.createNode(a, b, c, d);
}, lb(a, b, c) {
  if (16384 === (a.mode & 61440)) {
    try {
      var d = Fb(b, c);
    } catch (f) {
    }
    if (d) {
      for (var e in d.j) {
        throw new M(55);
      }
    }
  }
  delete a.parent.j[a.name];
  a.parent.timestamp = Date.now();
  a.name = c;
  b.j[c] = a;
  b.timestamp = a.parent.timestamp;
}, qb(a, b) {
  delete a.j[b];
  a.timestamp = Date.now();
}, mb(a, b) {
  var c = Fb(a, b), d;
  for (d in c.j) {
    throw new M(55);
  }
  delete a.j[b];
  a.timestamp = Date.now();
}, kb(a) {
  var b = [".", ".."], c;
  for (c of Object.keys(a.j)) {
    b.push(c);
  }
  return b;
}, xa(a, b, c) {
  a = N.createNode(a, b, 41471, 0);
  a.link = c;
  return a;
}, ia(a) {
  if (40960 !== (a.mode & 61440)) {
    throw new M(28);
  }
  return a.link;
},}, l:{read(a, b, c, d, e) {
  var f = a.node.j;
  if (e >= a.node.u) {
    return 0;
  }
  a = Math.min(a.node.u - e, d);
  if (8 < a && f.subarray) {
    b.set(f.subarray(e, e + a), c);
  } else {
    for (d = 0; d < a; d++) {
      b[c + d] = f[e + d];
    }
  }
  return a;
}, write(a, b, c, d, e, f) {
  b.buffer === y.buffer && (f = !1);
  if (!d) {
    return 0;
  }
  a = a.node;
  a.timestamp = Date.now();
  if (b.subarray && (!a.j || a.j.subarray)) {
    if (f) {
      return a.j = b.subarray(c, c + d), a.u = d;
    }
    if (0 === a.u && 0 === e) {
      return a.j = b.slice(c, c + d), a.u = d;
    }
    if (e + d <= a.u) {
      return a.j.set(b.subarray(c, c + d), e), d;
    }
  }
  Bb(a, e + d);
  if (a.j.subarray && b.subarray) {
    a.j.set(b.subarray(c, c + d), e);
  } else {
    for (f = 0; f < d; f++) {
      a.j[e + f] = b[c + f];
    }
  }
  a.u = Math.max(a.u, e + d);
  return d;
}, Z(a, b, c) {
  1 === c ? b += a.position : 2 === c && 32768 === (a.node.mode & 61440) && (b += a.node.u);
  if (0 > b) {
    throw new M(28);
  }
  return b;
}, Qa(a, b, c) {
  Bb(a.node, b + c);
  a.node.u = Math.max(a.node.u, b + c);
}, cb(a, b, c, d, e) {
  if (32768 !== (a.node.mode & 61440)) {
    throw new M(43);
  }
  a = a.node.j;
  if (e & 2 || a.buffer !== y.buffer) {
    if (0 < c || c + b < a.length) {
      a.subarray ? a = a.subarray(c, c + b) : a = Array.prototype.slice.call(a, c, c + b);
    }
    c = !0;
    Sa();
    b = void 0;
    if (!b) {
      throw new M(48);
    }
    y.set(a, b);
  } else {
    c = !1, b = a.byteOffset;
  }
  return {m:b, pc:c};
}, fb(a, b, c, d) {
  N.l.write(a, b, 0, d, c, !1);
  return 0;
},},}, Gb = (a, b) => {
  var c = 0;
  a && (c |= 365);
  b && (c |= 146);
  return c;
}, Hb = null, Ib = {}, Jb = [], Kb = 1, Lb = null, Mb = !0, M = class {
  constructor(a) {
    this.name = "ErrnoError";
    this.Y = a;
  }
}, Eb = {}, Nb = class {
  constructor() {
    this.ma = {};
    this.node = null;
  }
  get flags() {
    return this.ma.flags;
  }
  set flags(a) {
    this.ma.flags = a;
  }
  get position() {
    return this.ma.position;
  }
  set position(a) {
    this.ma.position = a;
  }
}, Ob = class {
  constructor(a, b, c, d) {
    a ||= this;
    this.parent = a;
    this.S = a.S;
    this.ra = null;
    this.id = Kb++;
    this.name = b;
    this.mode = c;
    this.i = {};
    this.l = {};
    this.ta = d;
  }
  get read() {
    return 365 === (this.mode & 365);
  }
  set read(a) {
    a ? this.mode |= 365 : this.mode &= -366;
  }
  get write() {
    return 146 === (this.mode & 146);
  }
  set write(a) {
    a ? this.mode |= 146 : this.mode &= -147;
  }
};
function Pb(a, b = {}) {
  a = nb(a);
  if (!a) {
    return {path:"", node:null};
  }
  b = Object.assign({Za:!0, Ia:0}, b);
  if (8 < b.Ia) {
    throw new M(32);
  }
  a = a.split("/").filter(g => !!g);
  for (var c = Hb, d = "/", e = 0; e < a.length; e++) {
    var f = e === a.length - 1;
    if (f && b.parent) {
      break;
    }
    c = Fb(c, a[e]);
    d = ib(d + "/" + a[e]);
    c.ra && (!f || f && b.Za) && (c = c.ra.root);
    if (!f || b.Ya) {
      for (f = 0; 40960 === (c.mode & 61440);) {
        if (c = Qb(d), d = nb(jb(d), c), c = Pb(d, {Ia:b.Ia + 1}).node, 40 < f++) {
          throw new M(32);
        }
      }
    }
  }
  return {path:d, node:c};
}
function Rb(a) {
  for (var b;;) {
    if (a === a.parent) {
      return a = a.S.eb, b ? "/" !== a[a.length - 1] ? `${a}/${b}` : a + b : a;
    }
    b = b ? `${a.name}/${b}` : a.name;
    a = a.parent;
  }
}
function Sb(a, b) {
  for (var c = 0, d = 0; d < b.length; d++) {
    c = (c << 5) - c + b.charCodeAt(d) | 0;
  }
  return (a + c >>> 0) % Lb.length;
}
function Fb(a, b) {
  var c = 16384 === (a.mode & 61440) ? (c = Tb(a, "x")) ? c : a.i.ga ? 0 : 2 : 54;
  if (c) {
    throw new M(c);
  }
  for (c = Lb[Sb(a.id, b)]; c; c = c.Xb) {
    var d = c.name;
    if (c.parent.id === a.id && d === b) {
      return c;
    }
  }
  return a.i.ga(a, b);
}
function Db(a, b, c, d) {
  a = new Ob(a, b, c, d);
  b = Sb(a.parent.id, a.name);
  a.Xb = Lb[b];
  return Lb[b] = a;
}
function Ub(a) {
  var b = ["r", "w", "rw"][a & 3];
  a & 512 && (b += "w");
  return b;
}
function Tb(a, b) {
  if (Mb) {
    return 0;
  }
  if (!b.includes("r") || a.mode & 292) {
    if (b.includes("w") && !(a.mode & 146) || b.includes("x") && !(a.mode & 73)) {
      return 2;
    }
  } else {
    return 2;
  }
  return 0;
}
function Vb(a, b) {
  try {
    return Fb(a, b), 20;
  } catch (c) {
  }
  return Tb(a, "wx");
}
function Wb(a) {
  a = Jb[a];
  if (!a) {
    throw new M(8);
  }
  return a;
}
function Xb(a, b = -1) {
  a = Object.assign(new Nb(), a);
  if (-1 == b) {
    a: {
      for (b = 0; 4096 >= b; b++) {
        if (!Jb[b]) {
          break a;
        }
      }
      throw new M(33);
    }
  }
  a.U = b;
  return Jb[b] = a;
}
function Yb(a, b = -1) {
  a = Xb(a, b);
  a.l?.zc?.(a);
  return a;
}
var Cb = {open(a) {
  a.l = Ib[a.node.ta].l;
  a.l.open?.(a);
}, Z() {
  throw new M(70);
},};
function xb(a, b) {
  Ib[a] = {l:b};
}
function Zb(a, b) {
  var c = "/" === b;
  if (c && Hb) {
    throw new M(10);
  }
  if (!c && b) {
    var d = Pb(b, {Za:!1});
    b = d.path;
    d = d.node;
    if (d.ra) {
      throw new M(10);
    }
    if (16384 !== (d.mode & 61440)) {
      throw new M(54);
    }
  }
  b = {type:a, Ic:{}, eb:b, Wb:[]};
  a = a.S(b);
  a.S = b;
  b.root = a;
  c ? Hb = a : d && (d.ra = b, d.S && d.S.Wb.push(b));
}
function ec(a, b, c) {
  var d = Pb(a, {parent:!0}).node;
  a = kb(a);
  if (!a || "." === a || ".." === a) {
    throw new M(28);
  }
  var e = Vb(d, a);
  if (e) {
    throw new M(e);
  }
  if (!d.i.qa) {
    throw new M(63);
  }
  return d.i.qa(d, a, b, c);
}
function fc(a) {
  return ec(a, 16895, 0);
}
function gc(a, b, c) {
  "undefined" == typeof c && (c = b, b = 438);
  ec(a, b | 8192, c);
}
function hc(a, b) {
  if (!nb(a)) {
    throw new M(44);
  }
  var c = Pb(b, {parent:!0}).node;
  if (!c) {
    throw new M(44);
  }
  b = kb(b);
  var d = Vb(c, b);
  if (d) {
    throw new M(d);
  }
  if (!c.i.xa) {
    throw new M(63);
  }
  c.i.xa(c, b, a);
}
function Qb(a) {
  a = Pb(a).node;
  if (!a) {
    throw new M(44);
  }
  if (!a.i.ia) {
    throw new M(28);
  }
  return nb(Rb(a.parent), a.i.ia(a));
}
function ic(a, b, c) {
  if ("" === a) {
    throw new M(44);
  }
  if ("string" == typeof b) {
    var d = {r:0, "r+":2, w:577, "w+":578, a:1089, "a+":1090,}[b];
    if ("undefined" == typeof d) {
      throw Error(`Unknown file open mode: ${b}`);
    }
    b = d;
  }
  c = b & 64 ? ("undefined" == typeof c ? 438 : c) & 4095 | 32768 : 0;
  if ("object" == typeof a) {
    var e = a;
  } else {
    a = ib(a);
    try {
      e = Pb(a, {Ya:!(b & 131072)}).node;
    } catch (f) {
    }
  }
  d = !1;
  if (b & 64) {
    if (e) {
      if (b & 128) {
        throw new M(20);
      }
    } else {
      e = ec(a, c, 0), d = !0;
    }
  }
  if (!e) {
    throw new M(44);
  }
  8192 === (e.mode & 61440) && (b &= -513);
  if (b & 65536 && 16384 !== (e.mode & 61440)) {
    throw new M(54);
  }
  if (!d && (c = e ? 40960 === (e.mode & 61440) ? 32 : 16384 === (e.mode & 61440) && ("r" !== Ub(b) || b & 512) ? 31 : Tb(e, Ub(b)) : 44)) {
    throw new M(c);
  }
  if (b & 512 && !d) {
    c = e;
    c = "string" == typeof c ? Pb(c, {Ya:!0}).node : c;
    if (!c.i.N) {
      throw new M(63);
    }
    if (16384 === (c.mode & 61440)) {
      throw new M(31);
    }
    if (32768 !== (c.mode & 61440)) {
      throw new M(28);
    }
    if (d = Tb(c, "w")) {
      throw new M(d);
    }
    c.i.N(c, {size:0, timestamp:Date.now()});
  }
  b &= -131713;
  e = Xb({node:e, path:Rb(e), flags:b, seekable:!0, position:0, l:e.l, jc:[], error:!1});
  e.l.open && e.l.open(e);
  !k.logReadFiles || b & 1 || (jc ||= {}, a in jc || (jc[a] = 1));
  return e;
}
function kc(a, b, c) {
  if (null === a.U) {
    throw new M(8);
  }
  if (!a.seekable || !a.l.Z) {
    throw new M(70);
  }
  if (0 != c && 1 != c && 2 != c) {
    throw new M(28);
  }
  a.position = a.l.Z(a, b, c);
  a.jc = [];
}
var lc;
function mc(a, b, c) {
  a = ib("/dev/" + a);
  var d = Gb(!!b, !!c);
  nc ||= 64;
  var e = nc++ << 8 | 0;
  xb(e, {open(f) {
    f.seekable = !1;
  }, close() {
    c?.buffer?.length && c(10);
  }, read(f, g, h, n) {
    for (var m = 0, r = 0; r < n; r++) {
      try {
        var w = b();
      } catch (x) {
        throw new M(29);
      }
      if (void 0 === w && 0 === m) {
        throw new M(6);
      }
      if (null === w || void 0 === w) {
        break;
      }
      m++;
      g[h + r] = w;
    }
    m && (f.node.timestamp = Date.now());
    return m;
  }, write(f, g, h, n) {
    for (var m = 0; m < n; m++) {
      try {
        c(g[h + m]);
      } catch (r) {
        throw new M(29);
      }
    }
    n && (f.node.timestamp = Date.now());
    return m;
  }});
  gc(a, d, e);
}
var nc, oc = {}, jc, gb = void 0, pc = (a, b) => Object.defineProperty(b, "name", {value:a}), qc = [], rc = [], O, P = a => {
  if (!a) {
    throw new O("Cannot use deleted val. handle = " + a);
  }
  return rc[a];
}, sc = a => {
  switch(a) {
    case void 0:
      return 2;
    case null:
      return 4;
    case !0:
      return 6;
    case !1:
      return 8;
    default:
      const b = qc.pop() || rc.length;
      rc[b] = a;
      rc[b + 1] = 1;
      return b;
  }
}, tc = a => {
  var b = Error, c = pc(a, function(d) {
    this.name = a;
    this.message = d;
    d = Error(d).stack;
    void 0 !== d && (this.stack = this.toString() + "\n" + d.replace(/^Error(:[^\n]*)?\n/, ""));
  });
  c.prototype = Object.create(b.prototype);
  c.prototype.constructor = c;
  c.prototype.toString = function() {
    return void 0 === this.message ? this.name : `${this.name}: ${this.message}`;
  };
  return c;
}, uc, vc, R = a => {
  for (var b = ""; A[a];) {
    b += vc[A[a++]];
  }
  return b;
}, wc = [], xc = () => {
  for (; wc.length;) {
    var a = wc.pop();
    a.g.ca = !1;
    a["delete"]();
  }
}, yc, zc = {}, Ac = (a, b) => {
  if (void 0 === b) {
    throw new O("ptr should not be undefined");
  }
  for (; a.B;) {
    b = a.ja(b), a = a.B;
  }
  return b;
}, Bc = {}, Ec = a => {
  a = Cc(a);
  var b = R(a);
  Dc(a);
  return b;
}, Fc = (a, b) => {
  var c = Bc[a];
  if (void 0 === c) {
    throw a = `${b} has unknown type ${Ec(a)}`, new O(a);
  }
  return c;
}, Gc = () => {
}, Hc = !1, Ic = (a, b, c) => {
  if (b === c) {
    return a;
  }
  if (void 0 === c.B) {
    return null;
  }
  a = Ic(a, b, c.B);
  return null === a ? null : c.Db(a);
}, Jc = {}, Kc = (a, b) => {
  b = Ac(a, b);
  return zc[b];
}, Lc, Nc = (a, b) => {
  if (!b.s || !b.m) {
    throw new Lc("makeClassHandle requires ptr and ptrType");
  }
  if (!!b.H !== !!b.C) {
    throw new Lc("Both smartPtrType and smartPtr must be specified");
  }
  b.count = {value:1};
  return Mc(Object.create(a, {g:{value:b, writable:!0,},}));
}, Mc = a => {
  if ("undefined" === typeof FinalizationRegistry) {
    return Mc = b => b, a;
  }
  Hc = new FinalizationRegistry(b => {
    b = b.g;
    --b.count.value;
    0 === b.count.value && (b.C ? b.H.M(b.C) : b.s.h.M(b.m));
  });
  Mc = b => {
    var c = b.g;
    c.C && Hc.register(b, {g:c}, b);
    return b;
  };
  Gc = b => {
    Hc.unregister(b);
  };
  return Mc(a);
}, Oc = {}, Pc = a => {
  for (; a.length;) {
    var b = a.pop();
    a.pop()(b);
  }
};
function Qc(a) {
  return this.fromWireType(E[a >> 2]);
}
var Rc = {}, Sc = {}, T = (a, b, c) => {
  function d(h) {
    h = c(h);
    if (h.length !== a.length) {
      throw new Lc("Mismatched type converter count");
    }
    for (var n = 0; n < a.length; ++n) {
      Tc(a[n], h[n]);
    }
  }
  a.forEach(function(h) {
    Sc[h] = b;
  });
  var e = Array(b.length), f = [], g = 0;
  b.forEach((h, n) => {
    Bc.hasOwnProperty(h) ? e[n] = Bc[h] : (f.push(h), Rc.hasOwnProperty(h) || (Rc[h] = []), Rc[h].push(() => {
      e[n] = Bc[h];
      ++g;
      g === f.length && d(e);
    }));
  });
  0 === f.length && d(e);
};
function Uc(a, b, c = {}) {
  var d = b.name;
  if (!a) {
    throw new O(`type "${d}" must have a positive integer typeid pointer`);
  }
  if (Bc.hasOwnProperty(a)) {
    if (c.Nb) {
      return;
    }
    throw new O(`Cannot register type '${d}' twice`);
  }
  Bc[a] = b;
  delete Sc[a];
  Rc.hasOwnProperty(a) && (b = Rc[a], delete Rc[a], b.forEach(e => e()));
}
function Tc(a, b, c = {}) {
  if (!("argPackAdvance" in b)) {
    throw new TypeError("registerType registeredInstance requires argPackAdvance");
  }
  return Uc(a, b, c);
}
var Vc = a => {
  throw new O(a.g.s.h.name + " instance already deleted");
};
function Wc() {
}
var Xc = (a, b, c) => {
  if (void 0 === a[b].v) {
    var d = a[b];
    a[b] = function(...e) {
      if (!a[b].v.hasOwnProperty(e.length)) {
        throw new O(`Function '${c}' called with an invalid number of arguments (${e.length}) - expects one of (${a[b].v})!`);
      }
      return a[b].v[e.length].apply(this, e);
    };
    a[b].v = [];
    a[b].v[d.ba] = d;
  }
}, Yc = (a, b, c) => {
  if (k.hasOwnProperty(a)) {
    if (void 0 === c || void 0 !== k[a].v && void 0 !== k[a].v[c]) {
      throw new O(`Cannot register public name '${a}' twice`);
    }
    Xc(k, a, a);
    if (k.hasOwnProperty(c)) {
      throw new O(`Cannot register multiple overloads of a function with the same number of arguments (${c})!`);
    }
    k[a].v[c] = b;
  } else {
    k[a] = b, void 0 !== c && (k[a].Hc = c);
  }
}, Zc = a => {
  if (void 0 === a) {
    return "_unknown";
  }
  a = a.replace(/[^a-zA-Z0-9_]/g, "$");
  var b = a.charCodeAt(0);
  return 48 <= b && 57 >= b ? `_${a}` : a;
};
function $c(a, b, c, d, e, f, g, h) {
  this.name = a;
  this.constructor = b;
  this.K = c;
  this.M = d;
  this.B = e;
  this.Ib = f;
  this.ja = g;
  this.Db = h;
  this.ib = [];
}
var ad = (a, b, c) => {
  for (; b !== c;) {
    if (!b.ja) {
      throw new O(`Expected null or instance of ${c.name}, got an instance of ${b.name}`);
    }
    a = b.ja(a);
    b = b.B;
  }
  return a;
};
function bd(a, b) {
  if (null === b) {
    if (this.Fa) {
      throw new O(`null is not a valid ${this.name}`);
    }
    return 0;
  }
  if (!b.g) {
    throw new O(`Cannot pass "${cd(b)}" as a ${this.name}`);
  }
  if (!b.g.m) {
    throw new O(`Cannot pass deleted object as a pointer of type ${this.name}`);
  }
  return ad(b.g.m, b.g.s.h, this.h);
}
function dd(a, b) {
  if (null === b) {
    if (this.Fa) {
      throw new O(`null is not a valid ${this.name}`);
    }
    if (this.pa) {
      var c = this.Ha();
      null !== a && a.push(this.M, c);
      return c;
    }
    return 0;
  }
  if (!b || !b.g) {
    throw new O(`Cannot pass "${cd(b)}" as a ${this.name}`);
  }
  if (!b.g.m) {
    throw new O(`Cannot pass deleted object as a pointer of type ${this.name}`);
  }
  if (!this.oa && b.g.s.oa) {
    throw new O(`Cannot convert argument of type ${b.g.H ? b.g.H.name : b.g.s.name} to parameter type ${this.name}`);
  }
  c = ad(b.g.m, b.g.s.h, this.h);
  if (this.pa) {
    if (void 0 === b.g.C) {
      throw new O("Passing raw pointer to smart pointer is illegal");
    }
    switch(this.dc) {
      case 0:
        if (b.g.H === this) {
          c = b.g.C;
        } else {
          throw new O(`Cannot convert argument of type ${b.g.H ? b.g.H.name : b.g.s.name} to parameter type ${this.name}`);
        }
        break;
      case 1:
        c = b.g.C;
        break;
      case 2:
        if (b.g.H === this) {
          c = b.g.C;
        } else {
          var d = b.clone();
          c = this.$b(c, sc(() => d["delete"]()));
          null !== a && a.push(this.M, c);
        }
        break;
      default:
        throw new O("Unsupporting sharing policy");
    }
  }
  return c;
}
function ed(a, b) {
  if (null === b) {
    if (this.Fa) {
      throw new O(`null is not a valid ${this.name}`);
    }
    return 0;
  }
  if (!b.g) {
    throw new O(`Cannot pass "${cd(b)}" as a ${this.name}`);
  }
  if (!b.g.m) {
    throw new O(`Cannot pass deleted object as a pointer of type ${this.name}`);
  }
  if (b.g.s.oa) {
    throw new O(`Cannot convert argument of type ${b.g.s.name} to parameter type ${this.name}`);
  }
  return ad(b.g.m, b.g.s.h, this.h);
}
function fd(a, b, c, d, e, f, g, h, n, m, r) {
  this.name = a;
  this.h = b;
  this.Fa = c;
  this.oa = d;
  this.pa = e;
  this.Zb = f;
  this.dc = g;
  this.jb = h;
  this.Ha = n;
  this.$b = m;
  this.M = r;
  e || void 0 !== b.B ? this.toWireType = dd : (this.toWireType = d ? bd : ed, this.J = null);
}
var gd = (a, b, c) => {
  if (!k.hasOwnProperty(a)) {
    throw new Lc("Replacing nonexistent public symbol");
  }
  void 0 !== k[a].v && void 0 !== c ? k[a].v[c] = b : (k[a] = b, k[a].ba = c);
}, hd = [], jd, kd = a => {
  var b = hd[a];
  b || (a >= hd.length && (hd.length = a + 1), hd[a] = b = jd.get(a));
  return b;
}, ld = (a, b, c = []) => {
  a.includes("j") ? (a = a.replace(/p/g, "i"), b = (0,k["dynCall_" + a])(b, ...c)) : b = kd(b)(...c);
  return b;
}, md = (a, b) => (...c) => ld(a, b, c), V = (a, b) => {
  a = R(a);
  var c = a.includes("j") ? md(a, b) : kd(b);
  if ("function" != typeof c) {
    throw new O(`unknown function pointer with signature ${a}: ${b}`);
  }
  return c;
}, nd, od = (a, b) => {
  function c(f) {
    e[f] || Bc[f] || (Sc[f] ? Sc[f].forEach(c) : (d.push(f), e[f] = !0));
  }
  var d = [], e = {};
  b.forEach(c);
  throw new nd(`${a}: ` + d.map(Ec).join([", "]));
};
function pd(a) {
  for (var b = 1; b < a.length; ++b) {
    if (null !== a[b] && void 0 === a[b].J) {
      return !0;
    }
  }
  return !1;
}
function td(a, b, c, d, e) {
  var f = b.length;
  if (2 > f) {
    throw new O("argTypes array size mismatch! Must at least get return value and 'this' types!");
  }
  var g = null !== b[1] && null !== c, h = pd(b), n = "void" !== b[0].name, m = f - 2, r = Array(m), w = [], x = [];
  return pc(a, function(...l) {
    if (l.length !== m) {
      throw new O(`function ${a} called with ${l.length} arguments, expected ${m}`);
    }
    x.length = 0;
    w.length = g ? 2 : 1;
    w[0] = e;
    if (g) {
      var t = b[1].toWireType(x, this);
      w[1] = t;
    }
    for (var q = 0; q < m; ++q) {
      r[q] = b[q + 2].toWireType(x, l[q]), w.push(r[q]);
    }
    l = d(...w);
    if (h) {
      Pc(x);
    } else {
      for (q = g ? 1 : 2; q < b.length; q++) {
        var C = 1 === q ? t : r[q - 2];
        null !== b[q].J && b[q].J(C);
      }
    }
    t = n ? b[0].fromWireType(l) : void 0;
    return t;
  });
}
var ud = (a, b) => {
  for (var c = [], d = 0; d < a; d++) {
    c.push(E[b + 4 * d >> 2]);
  }
  return c;
}, vd = a => {
  a = a.trim();
  const b = a.indexOf("(");
  return -1 !== b ? a.substr(0, b) : a;
}, wd = (a, b, c) => {
  if (!(a instanceof Object)) {
    throw new O(`${c} with invalid "this": ${a}`);
  }
  if (!(a instanceof b.h.constructor)) {
    throw new O(`${c} incompatible with "this" of type ${a.constructor.name}`);
  }
  if (!a.g.m) {
    throw new O(`cannot call emscripten binding method ${c} on deleted object`);
  }
  return ad(a.g.m, a.g.s.h, b.h);
}, xd = a => {
  9 < a && 0 === --rc[a + 1] && (rc[a] = void 0, qc.push(a));
}, yd = {name:"emscripten::val", fromWireType:a => {
  var b = P(a);
  xd(a);
  return b;
}, toWireType:(a, b) => sc(b), argPackAdvance:8, readValueFromPointer:Qc, J:null,}, zd = (a, b, c) => {
  switch(b) {
    case 1:
      return c ? function(d) {
        return this.fromWireType(y[d]);
      } : function(d) {
        return this.fromWireType(A[d]);
      };
    case 2:
      return c ? function(d) {
        return this.fromWireType(Ea[d >> 1]);
      } : function(d) {
        return this.fromWireType(Ha[d >> 1]);
      };
    case 4:
      return c ? function(d) {
        return this.fromWireType(B[d >> 2]);
      } : function(d) {
        return this.fromWireType(E[d >> 2]);
      };
    default:
      throw new TypeError(`invalid integer width (${b}): ${a}`);
  }
}, cd = a => {
  if (null === a) {
    return "null";
  }
  var b = typeof a;
  return "object" === b || "array" === b || "function" === b ? a.toString() : "" + a;
}, Ad = (a, b) => {
  switch(b) {
    case 4:
      return function(c) {
        return this.fromWireType(Ia[c >> 2]);
      };
    case 8:
      return function(c) {
        return this.fromWireType(Ja[c >> 3]);
      };
    default:
      throw new TypeError(`invalid float width (${b}): ${a}`);
  }
}, Bd = (a, b, c) => {
  switch(b) {
    case 1:
      return c ? d => y[d] : d => A[d];
    case 2:
      return c ? d => Ea[d >> 1] : d => Ha[d >> 1];
    case 4:
      return c ? d => B[d >> 2] : d => E[d >> 2];
    default:
      throw new TypeError(`invalid integer width (${b}): ${a}`);
  }
}, Cd = "undefined" != typeof TextDecoder ? new TextDecoder("utf-16le") : void 0, Dd = (a, b) => {
  var c = a >> 1;
  for (var d = c + b / 2; !(c >= d) && Ha[c];) {
    ++c;
  }
  c <<= 1;
  if (32 < c - a && Cd) {
    return Cd.decode(A.subarray(a, c));
  }
  c = "";
  for (d = 0; !(d >= b / 2); ++d) {
    var e = Ea[a + 2 * d >> 1];
    if (0 == e) {
      break;
    }
    c += String.fromCharCode(e);
  }
  return c;
}, Ed = (a, b, c) => {
  c ??= 2147483647;
  if (2 > c) {
    return 0;
  }
  c -= 2;
  var d = b;
  c = c < 2 * a.length ? c / 2 : a.length;
  for (var e = 0; e < c; ++e) {
    Ea[b >> 1] = a.charCodeAt(e), b += 2;
  }
  Ea[b >> 1] = 0;
  return b - d;
}, Fd = a => 2 * a.length, Gd = (a, b) => {
  for (var c = 0, d = ""; !(c >= b / 4);) {
    var e = B[a + 4 * c >> 2];
    if (0 == e) {
      break;
    }
    ++c;
    65536 <= e ? (e -= 65536, d += String.fromCharCode(55296 | e >> 10, 56320 | e & 1023)) : d += String.fromCharCode(e);
  }
  return d;
}, Hd = (a, b, c) => {
  c ??= 2147483647;
  if (4 > c) {
    return 0;
  }
  var d = b;
  c = d + c - 4;
  for (var e = 0; e < a.length; ++e) {
    var f = a.charCodeAt(e);
    if (55296 <= f && 57343 >= f) {
      var g = a.charCodeAt(++e);
      f = 65536 + ((f & 1023) << 10) | g & 1023;
    }
    B[b >> 2] = f;
    b += 4;
    if (b + 4 > c) {
      break;
    }
  }
  B[b >> 2] = 0;
  return b - d;
}, Id = a => {
  for (var b = 0, c = 0; c < a.length; ++c) {
    var d = a.charCodeAt(c);
    55296 <= d && 57343 >= d && ++c;
    b += 4;
  }
  return b;
}, Jd = (a, b, c) => {
  var d = [];
  a = a.toWireType(d, c);
  d.length && (E[b >> 2] = sc(d));
  return a;
}, Kd = [], Ld = {}, Md = a => {
  var b = Ld[a];
  return void 0 === b ? R(a) : b;
}, Nd = a => {
  var b = Kd.length;
  Kd.push(a);
  return b;
}, Od = (a, b) => {
  for (var c = Array(a), d = 0; d < a; ++d) {
    c[d] = Fc(E[b + 4 * d >> 2], "parameter " + d);
  }
  return c;
}, Pd = Reflect.construct, Qd = a => 0 === a % 4 && (0 !== a % 100 || 0 === a % 400), Rd = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335], Sd = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334], Td = [], Ud = {}, Wd = () => {
  if (!Vd) {
    var a = {USER:"web_user", LOGNAME:"web_user", PATH:"/", PWD:"/", HOME:"/home/web_user", LANG:("object" == typeof navigator && navigator.languages && navigator.languages[0] || "C").replace("-", "_") + ".UTF-8", _:sa || "./this.program"}, b;
    for (b in Ud) {
      void 0 === Ud[b] ? delete a[b] : a[b] = Ud[b];
    }
    var c = [];
    for (b in a) {
      c.push(`${b}=${a[b]}`);
    }
    Vd = c;
  }
  return Vd;
}, Vd, Xd = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31], Yd = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31], Zd = (a, b, c, d) => {
  function e(l, t, q) {
    for (l = "number" == typeof l ? l.toString() : l || ""; l.length < t;) {
      l = q[0] + l;
    }
    return l;
  }
  function f(l, t) {
    return e(l, t, "0");
  }
  function g(l, t) {
    function q(H) {
      return 0 > H ? -1 : 0 < H ? 1 : 0;
    }
    var C;
    0 === (C = q(l.getFullYear() - t.getFullYear())) && 0 === (C = q(l.getMonth() - t.getMonth())) && (C = q(l.getDate() - t.getDate()));
    return C;
  }
  function h(l) {
    switch(l.getDay()) {
      case 0:
        return new Date(l.getFullYear() - 1, 11, 29);
      case 1:
        return l;
      case 2:
        return new Date(l.getFullYear(), 0, 3);
      case 3:
        return new Date(l.getFullYear(), 0, 2);
      case 4:
        return new Date(l.getFullYear(), 0, 1);
      case 5:
        return new Date(l.getFullYear() - 1, 11, 31);
      case 6:
        return new Date(l.getFullYear() - 1, 11, 30);
    }
  }
  function n(l) {
    var t = l.$;
    for (l = new Date((new Date(l.aa + 1900, 0, 1)).getTime()); 0 < t;) {
      var q = l.getMonth(), C = (Qd(l.getFullYear()) ? Xd : Yd)[q];
      if (t > C - l.getDate()) {
        t -= C - l.getDate() + 1, l.setDate(1), 11 > q ? l.setMonth(q + 1) : (l.setMonth(0), l.setFullYear(l.getFullYear() + 1));
      } else {
        l.setDate(l.getDate() + t);
        break;
      }
    }
    q = new Date(l.getFullYear() + 1, 0, 4);
    t = h(new Date(l.getFullYear(), 0, 4));
    q = h(q);
    return 0 >= g(t, l) ? 0 >= g(q, l) ? l.getFullYear() + 1 : l.getFullYear() : l.getFullYear() - 1;
  }
  var m = E[d + 40 >> 2];
  d = {hc:B[d >> 2], fc:B[d + 4 >> 2], ya:B[d + 8 >> 2], Ka:B[d + 12 >> 2], za:B[d + 16 >> 2], aa:B[d + 20 >> 2], O:B[d + 24 >> 2], $:B[d + 28 >> 2], Kc:B[d + 32 >> 2], ec:B[d + 36 >> 2], ic:m ? m ? pb(A, m) : "" : ""};
  c = c ? pb(A, c) : "";
  m = {"%c":"%a %b %d %H:%M:%S %Y", "%D":"%m/%d/%y", "%F":"%Y-%m-%d", "%h":"%b", "%r":"%I:%M:%S %p", "%R":"%H:%M", "%T":"%H:%M:%S", "%x":"%m/%d/%y", "%X":"%H:%M:%S", "%Ec":"%c", "%EC":"%C", "%Ex":"%m/%d/%y", "%EX":"%H:%M:%S", "%Ey":"%y", "%EY":"%Y", "%Od":"%d", "%Oe":"%e", "%OH":"%H", "%OI":"%I", "%Om":"%m", "%OM":"%M", "%OS":"%S", "%Ou":"%u", "%OU":"%U", "%OV":"%V", "%Ow":"%w", "%OW":"%W", "%Oy":"%y",};
  for (var r in m) {
    c = c.replace(new RegExp(r, "g"), m[r]);
  }
  var w = "Sunday Monday Tuesday Wednesday Thursday Friday Saturday".split(" "), x = "January February March April May June July August September October November December".split(" ");
  m = {"%a":l => w[l.O].substring(0, 3), "%A":l => w[l.O], "%b":l => x[l.za].substring(0, 3), "%B":l => x[l.za], "%C":l => f((l.aa + 1900) / 100 | 0, 2), "%d":l => f(l.Ka, 2), "%e":l => e(l.Ka, 2, " "), "%g":l => n(l).toString().substring(2), "%G":n, "%H":l => f(l.ya, 2), "%I":l => {
    l = l.ya;
    0 == l ? l = 12 : 12 < l && (l -= 12);
    return f(l, 2);
  }, "%j":l => {
    for (var t = 0, q = 0; q <= l.za - 1; t += (Qd(l.aa + 1900) ? Xd : Yd)[q++]) {
    }
    return f(l.Ka + t, 3);
  }, "%m":l => f(l.za + 1, 2), "%M":l => f(l.fc, 2), "%n":() => "\n", "%p":l => 0 <= l.ya && 12 > l.ya ? "AM" : "PM", "%S":l => f(l.hc, 2), "%t":() => "\t", "%u":l => l.O || 7, "%U":l => f(Math.floor((l.$ + 7 - l.O) / 7), 2), "%V":l => {
    var t = Math.floor((l.$ + 7 - (l.O + 6) % 7) / 7);
    2 >= (l.O + 371 - l.$ - 2) % 7 && t++;
    if (t) {
      53 == t && (q = (l.O + 371 - l.$) % 7, 4 == q || 3 == q && Qd(l.aa) || (t = 1));
    } else {
      t = 52;
      var q = (l.O + 7 - l.$ - 1) % 7;
      (4 == q || 5 == q && Qd(l.aa % 400 - 1)) && t++;
    }
    return f(t, 2);
  }, "%w":l => l.O, "%W":l => f(Math.floor((l.$ + 7 - (l.O + 6) % 7) / 7), 2), "%y":l => (l.aa + 1900).toString().substring(2), "%Y":l => l.aa + 1900, "%z":l => {
    l = l.ec;
    var t = 0 <= l;
    l = Math.abs(l) / 60;
    return (t ? "+" : "-") + String("0000" + (l / 60 * 100 + l % 60)).slice(-4);
  }, "%Z":l => l.ic, "%%":() => "%"};
  c = c.replace(/%%/g, "\x00\x00");
  for (r in m) {
    c.includes(r) && (c = c.replace(new RegExp(r, "g"), m[r](d)));
  }
  c = c.replace(/\0\0/g, "%");
  r = ub(c, !1);
  if (r.length > b) {
    return 0;
  }
  y.set(r, a);
  return r.length - 1;
};
[44].forEach(a => {
  Eb[a] = new M(a);
  Eb[a].stack = "<generic error, no stack>";
});
Lb = Array(4096);
Zb(N, "/");
fc("/tmp");
fc("/home");
fc("/home/web_user");
(function() {
  fc("/dev");
  xb(259, {read:() => 0, write:(d, e, f, g) => g,});
  gc("/dev/null", 259);
  wb(1280, zb);
  wb(1536, Ab);
  gc("/dev/tty", 1280);
  gc("/dev/tty1", 1536);
  var a = new Uint8Array(1024), b = 0, c = () => {
    0 === b && (b = mb(a).byteLength);
    return a[--b];
  };
  mc("random", c);
  mc("urandom", c);
  fc("/dev/shm");
  fc("/dev/shm/tmp");
})();
(function() {
  fc("/proc");
  var a = fc("/proc/self");
  fc("/proc/self/fd");
  Zb({S() {
    var b = Db(a, "fd", 16895, 73);
    b.i = {ga(c, d) {
      var e = Wb(+d);
      c = {parent:null, S:{eb:"fake"}, i:{ia:() => e.path},};
      return c.parent = c;
    }};
    return b;
  }}, "/proc/self/fd");
})();
O = k.BindingError = class extends Error {
  constructor(a) {
    super(a);
    this.name = "BindingError";
  }
};
rc.push(0, 1, void 0, 1, null, 1, !0, 1, !1, 1,);
k.count_emval_handles = () => rc.length / 2 - 5 - qc.length;
uc = k.PureVirtualError = tc("PureVirtualError");
for (var $d = Array(256), ae = 0; 256 > ae; ++ae) {
  $d[ae] = String.fromCharCode(ae);
}
vc = $d;
k.getInheritedInstanceCount = () => Object.keys(zc).length;
k.getLiveInheritedInstances = () => {
  var a = [], b;
  for (b in zc) {
    zc.hasOwnProperty(b) && a.push(zc[b]);
  }
  return a;
};
k.flushPendingDeletes = xc;
k.setDelayFunction = a => {
  yc = a;
  wc.length && yc && yc(xc);
};
Lc = k.InternalError = class extends Error {
  constructor(a) {
    super(a);
    this.name = "InternalError";
  }
};
Object.assign(Wc.prototype, {isAliasOf:function(a) {
  if (!(this instanceof Wc && a instanceof Wc)) {
    return !1;
  }
  var b = this.g.s.h, c = this.g.m;
  a.g = a.g;
  var d = a.g.s.h;
  for (a = a.g.m; b.B;) {
    c = b.ja(c), b = b.B;
  }
  for (; d.B;) {
    a = d.ja(a), d = d.B;
  }
  return b === d && c === a;
}, clone:function() {
  this.g.m || Vc(this);
  if (this.g.ea) {
    return this.g.count.value += 1, this;
  }
  var a = Mc, b = Object, c = b.create, d = Object.getPrototypeOf(this), e = this.g;
  a = a(c.call(b, d, {g:{value:{count:e.count, ca:e.ca, ea:e.ea, m:e.m, s:e.s, C:e.C, H:e.H,},}}));
  a.g.count.value += 1;
  a.g.ca = !1;
  return a;
}, ["delete"]() {
  this.g.m || Vc(this);
  if (this.g.ca && !this.g.ea) {
    throw new O("Object already scheduled for deletion");
  }
  Gc(this);
  var a = this.g;
  --a.count.value;
  0 === a.count.value && (a.C ? a.H.M(a.C) : a.s.h.M(a.m));
  this.g.ea || (this.g.C = void 0, this.g.m = void 0);
}, isDeleted:function() {
  return !this.g.m;
}, deleteLater:function() {
  this.g.m || Vc(this);
  if (this.g.ca && !this.g.ea) {
    throw new O("Object already scheduled for deletion");
  }
  wc.push(this);
  1 === wc.length && yc && yc(xc);
  this.g.ca = !0;
  return this;
},});
Object.assign(fd.prototype, {Jb(a) {
  this.jb && (a = this.jb(a));
  return a;
}, Ua(a) {
  this.M?.(a);
}, argPackAdvance:8, readValueFromPointer:Qc, fromWireType:function(a) {
  function b() {
    return this.pa ? Nc(this.h.K, {s:this.Zb, m:c, H:this, C:a,}) : Nc(this.h.K, {s:this, m:a,});
  }
  var c = this.Jb(a);
  if (!c) {
    return this.Ua(a), null;
  }
  var d = Kc(this.h, c);
  if (void 0 !== d) {
    if (0 === d.g.count.value) {
      return d.g.m = c, d.g.C = a, d.clone();
    }
    d = d.clone();
    this.Ua(a);
    return d;
  }
  d = this.h.Ib(c);
  d = Jc[d];
  if (!d) {
    return b.call(this);
  }
  d = this.oa ? d.zb : d.pointerType;
  var e = Ic(c, this.h, d.h);
  return null === e ? b.call(this) : this.pa ? Nc(d.h.K, {s:d, m:e, H:this, C:a,}) : Nc(d.h.K, {s:d, m:e,});
},});
nd = k.UnboundTypeError = tc("UnboundTypeError");
var de = {__syscall_fcntl64:function(a, b, c) {
  gb = c;
  try {
    var d = Wb(a);
    switch(b) {
      case 0:
        var e = fb();
        if (0 > e) {
          break;
        }
        for (; Jb[e];) {
          e++;
        }
        return Yb(d, e).U;
      case 1:
      case 2:
        return 0;
      case 3:
        return d.flags;
      case 4:
        return e = fb(), d.flags |= e, 0;
      case 12:
        return e = fb(), Ea[e + 0 >> 1] = 2, 0;
      case 13:
      case 14:
        return 0;
    }
    return -28;
  } catch (f) {
    if ("undefined" == typeof oc || "ErrnoError" !== f.name) {
      throw f;
    }
    return -f.Y;
  }
}, __syscall_ioctl:function(a, b, c) {
  gb = c;
  try {
    var d = Wb(a);
    switch(b) {
      case 21509:
        return d.o ? 0 : -59;
      case 21505:
        if (!d.o) {
          return -59;
        }
        if (d.o.T.Pb) {
          a = [3, 28, 127, 21, 4, 0, 1, 0, 17, 19, 26, 0, 18, 15, 23, 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,];
          var e = fb();
          B[e >> 2] = 25856;
          B[e + 4 >> 2] = 5;
          B[e + 8 >> 2] = 191;
          B[e + 12 >> 2] = 35387;
          for (var f = 0; 32 > f; f++) {
            y[e + f + 17] = a[f] || 0;
          }
        }
        return 0;
      case 21510:
      case 21511:
      case 21512:
        return d.o ? 0 : -59;
      case 21506:
      case 21507:
      case 21508:
        if (!d.o) {
          return -59;
        }
        if (d.o.T.Qb) {
          for (e = fb(), a = [], f = 0; 32 > f; f++) {
            a.push(y[e + f + 17]);
          }
        }
        return 0;
      case 21519:
        if (!d.o) {
          return -59;
        }
        e = fb();
        return B[e >> 2] = 0;
      case 21520:
        return d.o ? -28 : -59;
      case 21531:
        e = fb();
        if (!d.l.Ob) {
          throw new M(59);
        }
        return d.l.Ob(d, b, e);
      case 21523:
        if (!d.o) {
          return -59;
        }
        d.o.T.Rb && (f = [24, 80], e = fb(), Ea[e >> 1] = f[0], Ea[e + 2 >> 1] = f[1]);
        return 0;
      case 21524:
        return d.o ? 0 : -59;
      case 21515:
        return d.o ? 0 : -59;
      default:
        return -28;
    }
  } catch (g) {
    if ("undefined" == typeof oc || "ErrnoError" !== g.name) {
      throw g;
    }
    return -g.Y;
  }
}, __syscall_openat:function(a, b, c, d) {
  gb = d;
  try {
    b = b ? pb(A, b) : "";
    var e = b;
    if ("/" === e.charAt(0)) {
      b = e;
    } else {
      var f = -100 === a ? "/" : Wb(a).path;
      if (0 == e.length) {
        throw new M(44);
      }
      b = ib(f + "/" + e);
    }
    var g = d ? fb() : 0;
    return ic(b, c, g).U;
  } catch (h) {
    if ("undefined" == typeof oc || "ErrnoError" !== h.name) {
      throw h;
    }
    return -h.Y;
  }
}, _abort_js:() => {
  Sa("");
}, _embind_create_inheriting_constructor:(a, b, c) => {
  a = R(a);
  b = Fc(b, "wrapper");
  c = P(c);
  var d = b.h, e = d.K, f = d.B.K, g = d.B.constructor;
  a = pc(a, function(...h) {
    d.B.ib.forEach(function(n) {
      if (this[n] === f[n]) {
        throw new uc(`Pure virtual function ${n} must be implemented in JavaScript`);
      }
    }.bind(this));
    Object.defineProperty(this, "__parent", {value:e});
    this.__construct(...h);
  });
  e.__construct = function(...h) {
    if (this === e) {
      throw new O("Pass correct 'this' to __construct");
    }
    h = g.implement(this, ...h);
    Gc(h);
    var n = h.g;
    h.notifyOnDestruction();
    n.ea = !0;
    Object.defineProperties(this, {g:{value:n}});
    Mc(this);
    h = n.m;
    h = Ac(d, h);
    if (zc.hasOwnProperty(h)) {
      throw new O(`Tried to register registered instance: ${h}`);
    }
    zc[h] = this;
  };
  e.__destruct = function() {
    if (this === e) {
      throw new O("Pass correct 'this' to __destruct");
    }
    Gc(this);
    var h = this.g.m;
    h = Ac(d, h);
    if (zc.hasOwnProperty(h)) {
      delete zc[h];
    } else {
      throw new O(`Tried to unregister unregistered instance: ${h}`);
    }
  };
  a.prototype = Object.create(e);
  Object.assign(a.prototype, c);
  return sc(a);
}, _embind_finalize_value_object:a => {
  var b = Oc[a];
  delete Oc[a];
  var c = b.Ha, d = b.M, e = b.Xa, f = e.map(g => g.Mb).concat(e.map(g => g.bc));
  T([a], f, g => {
    var h = {};
    e.forEach((n, m) => {
      var r = g[m], w = n.Kb, x = n.Lb, l = g[m + e.length], t = n.ac, q = n.cc;
      h[n.Gb] = {read:C => r.fromWireType(w(x, C)), write:(C, H) => {
        var v = [];
        t(q, C, l.toWireType(v, H));
        Pc(v);
      }};
    });
    return [{name:b.name, fromWireType:n => {
      var m = {}, r;
      for (r in h) {
        m[r] = h[r].read(n);
      }
      d(n);
      return m;
    }, toWireType:(n, m) => {
      for (var r in h) {
        if (!(r in m)) {
          throw new TypeError(`Missing field: "${r}"`);
        }
      }
      var w = c();
      for (r in h) {
        h[r].write(w, m[r]);
      }
      null !== n && n.push(d, w);
      return w;
    }, argPackAdvance:8, readValueFromPointer:Qc, J:d,}];
  });
}, _embind_register_bigint:() => {
}, _embind_register_bool:(a, b, c, d) => {
  b = R(b);
  Tc(a, {name:b, fromWireType:function(e) {
    return !!e;
  }, toWireType:function(e, f) {
    return f ? c : d;
  }, argPackAdvance:8, readValueFromPointer:function(e) {
    return this.fromWireType(A[e]);
  }, J:null,});
}, _embind_register_class:(a, b, c, d, e, f, g, h, n, m, r, w, x) => {
  r = R(r);
  f = V(e, f);
  h &&= V(g, h);
  m &&= V(n, m);
  x = V(w, x);
  var l = Zc(r);
  Yc(l, function() {
    od(`Cannot construct ${r} due to unbound types`, [d]);
  });
  T([a, b, c], d ? [d] : [], t => {
    t = t[0];
    if (d) {
      var q = t.h;
      var C = q.K;
    } else {
      C = Wc.prototype;
    }
    t = pc(r, function(...Q) {
      if (Object.getPrototypeOf(this) !== H) {
        throw new O("Use 'new' to construct " + r);
      }
      if (void 0 === v.X) {
        throw new O(r + " has no accessible constructor");
      }
      var U = v.X[Q.length];
      if (void 0 === U) {
        throw new O(`Tried to invoke ctor of ${r} with invalid number of parameters (${Q.length}) - expected (${Object.keys(v.X).toString()}) parameters instead!`);
      }
      return U.apply(this, Q);
    });
    var H = Object.create(C, {constructor:{value:t},});
    t.prototype = H;
    var v = new $c(r, t, H, x, q, f, h, m);
    if (v.B) {
      var K;
      (K = v.B).ka ?? (K.ka = []);
      v.B.ka.push(v);
    }
    q = new fd(r, v, !0, !1, !1);
    K = new fd(r + "*", v, !1, !1, !1);
    C = new fd(r + " const*", v, !1, !0, !1);
    Jc[a] = {pointerType:K, zb:C};
    gd(l, t);
    return [q, K, C];
  });
}, _embind_register_class_class_function:(a, b, c, d, e, f, g) => {
  var h = ud(c, d);
  b = R(b);
  b = vd(b);
  f = V(e, f);
  T([], [a], n => {
    function m() {
      od(`Cannot call ${r} due to unbound types`, h);
    }
    n = n[0];
    var r = `${n.name}.${b}`;
    b.startsWith("@@") && (b = Symbol[b.substring(2)]);
    var w = n.h.constructor;
    void 0 === w[b] ? (m.ba = c - 1, w[b] = m) : (Xc(w, b, r), w[b].v[c - 1] = m);
    T([], h, x => {
      x = td(r, [x[0], null].concat(x.slice(1)), null, f, g);
      void 0 === w[b].v ? (x.ba = c - 1, w[b] = x) : w[b].v[c - 1] = x;
      if (n.h.ka) {
        for (const l of n.h.ka) {
          l.constructor.hasOwnProperty(b) || (l.constructor[b] = x);
        }
      }
      return [];
    });
    return [];
  });
}, _embind_register_class_class_property:(a, b, c, d, e, f, g, h) => {
  b = R(b);
  f = V(e, f);
  T([], [a], n => {
    n = n[0];
    var m = `${n.name}.${b}`, r = {get() {
      od(`Cannot access ${m} due to unbound types`, [c]);
    }, enumerable:!0, configurable:!0};
    r.set = h ? () => {
      od(`Cannot access ${m} due to unbound types`, [c]);
    } : () => {
      throw new O(`${m} is a read-only property`);
    };
    Object.defineProperty(n.h.constructor, b, r);
    T([], [c], w => {
      w = w[0];
      var x = {get() {
        return w.fromWireType(f(d));
      }, enumerable:!0};
      h && (h = V(g, h), x.set = l => {
        var t = [];
        h(d, w.toWireType(t, l));
        Pc(t);
      });
      Object.defineProperty(n.h.constructor, b, x);
      return [];
    });
    return [];
  });
}, _embind_register_class_constructor:(a, b, c, d, e, f) => {
  var g = ud(b, c);
  e = V(d, e);
  T([], [a], h => {
    h = h[0];
    var n = `constructor ${h.name}`;
    void 0 === h.h.X && (h.h.X = []);
    if (void 0 !== h.h.X[b - 1]) {
      throw new O(`Cannot register multiple constructors with identical number of parameters (${b - 1}) for class '${h.name}'! Overload resolution is currently only performed using the parameter count, not actual type info!`);
    }
    h.h.X[b - 1] = () => {
      od(`Cannot construct ${h.name} due to unbound types`, g);
    };
    T([], g, m => {
      m.splice(1, 0, null);
      h.h.X[b - 1] = td(n, m, null, e, f);
      return [];
    });
    return [];
  });
}, _embind_register_class_function:(a, b, c, d, e, f, g, h) => {
  var n = ud(c, d);
  b = R(b);
  b = vd(b);
  f = V(e, f);
  T([], [a], m => {
    function r() {
      od(`Cannot call ${w} due to unbound types`, n);
    }
    m = m[0];
    var w = `${m.name}.${b}`;
    b.startsWith("@@") && (b = Symbol[b.substring(2)]);
    h && m.h.ib.push(b);
    var x = m.h.K, l = x[b];
    void 0 === l || void 0 === l.v && l.className !== m.name && l.ba === c - 2 ? (r.ba = c - 2, r.className = m.name, x[b] = r) : (Xc(x, b, w), x[b].v[c - 2] = r);
    T([], n, t => {
      t = td(w, t, m, f, g);
      void 0 === x[b].v ? (t.ba = c - 2, x[b] = t) : x[b].v[c - 2] = t;
      return [];
    });
    return [];
  });
}, _embind_register_class_property:(a, b, c, d, e, f, g, h, n, m) => {
  b = R(b);
  e = V(d, e);
  T([], [a], r => {
    r = r[0];
    var w = `${r.name}.${b}`, x = {get() {
      od(`Cannot access ${w} due to unbound types`, [c, g]);
    }, enumerable:!0, configurable:!0};
    x.set = n ? () => od(`Cannot access ${w} due to unbound types`, [c, g]) : () => {
      throw new O(w + " is a read-only property");
    };
    Object.defineProperty(r.h.K, b, x);
    T([], n ? [c, g] : [c], l => {
      var t = l[0], q = {get() {
        var H = wd(this, r, w + " getter");
        return t.fromWireType(e(f, H));
      }, enumerable:!0};
      if (n) {
        n = V(h, n);
        var C = l[1];
        q.set = function(H) {
          var v = wd(this, r, w + " setter"), K = [];
          n(m, v, C.toWireType(K, H));
          Pc(K);
        };
      }
      Object.defineProperty(r.h.K, b, q);
      return [];
    });
    return [];
  });
}, _embind_register_emval:a => Tc(a, yd), _embind_register_enum:(a, b, c, d) => {
  function e() {
  }
  b = R(b);
  e.values = {};
  Tc(a, {name:b, constructor:e, fromWireType:function(f) {
    return this.constructor.values[f];
  }, toWireType:(f, g) => g.value, argPackAdvance:8, readValueFromPointer:zd(b, c, d), J:null,});
  Yc(b, e);
}, _embind_register_enum_value:(a, b, c) => {
  var d = Fc(a, "enum");
  b = R(b);
  a = d.constructor;
  d = Object.create(d.constructor.prototype, {value:{value:c}, constructor:{value:pc(`${d.name}_${b}`, function() {
  })},});
  a.values[c] = d;
  a[b] = d;
}, _embind_register_float:(a, b, c) => {
  b = R(b);
  Tc(a, {name:b, fromWireType:d => d, toWireType:(d, e) => e, argPackAdvance:8, readValueFromPointer:Ad(b, c), J:null,});
}, _embind_register_function:(a, b, c, d, e, f) => {
  var g = ud(b, c);
  a = R(a);
  a = vd(a);
  e = V(d, e);
  Yc(a, function() {
    od(`Cannot call ${a} due to unbound types`, g);
  }, b - 1);
  T([], g, h => {
    gd(a, td(a, [h[0], null].concat(h.slice(1)), null, e, f), b - 1);
    return [];
  });
}, _embind_register_integer:(a, b, c, d, e) => {
  b = R(b);
  -1 === e && (e = 4294967295);
  e = h => h;
  if (0 === d) {
    var f = 32 - 8 * c;
    e = h => h << f >>> f;
  }
  var g = b.includes("unsigned") ? function(h, n) {
    return n >>> 0;
  } : function(h, n) {
    return n;
  };
  Tc(a, {name:b, fromWireType:e, toWireType:g, argPackAdvance:8, readValueFromPointer:Bd(b, c, 0 !== d), J:null,});
}, _embind_register_memory_view:(a, b, c) => {
  function d(f) {
    return new e(y.buffer, E[f + 4 >> 2], E[f >> 2]);
  }
  var e = [Int8Array, Uint8Array, Int16Array, Uint16Array, Int32Array, Uint32Array, Float32Array, Float64Array,][b];
  c = R(c);
  Tc(a, {name:c, fromWireType:d, argPackAdvance:8, readValueFromPointer:d,}, {Nb:!0,});
}, _embind_register_std_string:(a, b) => {
  b = R(b);
  var c = "std::string" === b;
  Tc(a, {name:b, fromWireType:function(d) {
    var e = E[d >> 2], f = d + 4;
    if (c) {
      for (var g = f, h = 0; h <= e; ++h) {
        var n = f + h;
        if (h == e || 0 == A[n]) {
          g = g ? pb(A, g, n - g) : "";
          if (void 0 === m) {
            var m = g;
          } else {
            m += String.fromCharCode(0), m += g;
          }
          g = n + 1;
        }
      }
    } else {
      m = Array(e);
      for (h = 0; h < e; ++h) {
        m[h] = String.fromCharCode(A[f + h]);
      }
      m = m.join("");
    }
    Dc(d);
    return m;
  }, toWireType:function(d, e) {
    e instanceof ArrayBuffer && (e = new Uint8Array(e));
    var f = "string" == typeof e;
    if (!(f || e instanceof Uint8Array || e instanceof Uint8ClampedArray || e instanceof Int8Array)) {
      throw new O("Cannot pass non-string to std::string");
    }
    var g = c && f ? rb(e) : e.length;
    var h = be(4 + g + 1), n = h + 4;
    E[h >> 2] = g;
    if (c && f) {
      tb(e, A, n, g + 1);
    } else {
      if (f) {
        for (f = 0; f < g; ++f) {
          var m = e.charCodeAt(f);
          if (255 < m) {
            throw Dc(n), new O("String has UTF-16 code units that do not fit in 8 bits");
          }
          A[n + f] = m;
        }
      } else {
        for (f = 0; f < g; ++f) {
          A[n + f] = e[f];
        }
      }
    }
    null !== d && d.push(Dc, h);
    return h;
  }, argPackAdvance:8, readValueFromPointer:Qc, J(d) {
    Dc(d);
  },});
}, _embind_register_std_wstring:(a, b, c) => {
  c = R(c);
  if (2 === b) {
    var d = Dd;
    var e = Ed;
    var f = Fd;
    var g = h => Ha[h >> 1];
  } else {
    4 === b && (d = Gd, e = Hd, f = Id, g = h => E[h >> 2]);
  }
  Tc(a, {name:c, fromWireType:h => {
    for (var n = E[h >> 2], m, r = h + 4, w = 0; w <= n; ++w) {
      var x = h + 4 + w * b;
      if (w == n || 0 == g(x)) {
        r = d(r, x - r), void 0 === m ? m = r : (m += String.fromCharCode(0), m += r), r = x + b;
      }
    }
    Dc(h);
    return m;
  }, toWireType:(h, n) => {
    if ("string" != typeof n) {
      throw new O(`Cannot pass non-string to C++ string type ${c}`);
    }
    var m = f(n), r = be(4 + m + b);
    E[r >> 2] = m / b;
    e(n, r + 4, m + b);
    null !== h && h.push(Dc, r);
    return r;
  }, argPackAdvance:8, readValueFromPointer:Qc, J(h) {
    Dc(h);
  }});
}, _embind_register_value_object:(a, b, c, d, e, f) => {
  Oc[a] = {name:R(b), Ha:V(c, d), M:V(e, f), Xa:[],};
}, _embind_register_value_object_field:(a, b, c, d, e, f, g, h, n, m) => {
  Oc[a].Xa.push({Gb:R(b), Mb:c, Kb:V(d, e), Lb:f, bc:g, ac:V(h, n), cc:m,});
}, _embind_register_void:(a, b) => {
  b = R(b);
  Tc(a, {Dc:!0, name:b, argPackAdvance:0, fromWireType:() => {
  }, toWireType:() => {
  },});
}, _emscripten_get_now_is_monotonic:() => 1, _emscripten_memcpy_js:(a, b, c) => A.copyWithin(a, b, b + c), _emscripten_throw_longjmp:() => {
  throw Infinity;
}, _emval_as:(a, b, c) => {
  a = P(a);
  b = Fc(b, "emval::as");
  return Jd(b, c, a);
}, _emval_call:(a, b, c, d) => {
  a = Kd[a];
  b = P(b);
  return a(null, b, c, d);
}, _emval_call_method:(a, b, c, d, e) => {
  a = Kd[a];
  b = P(b);
  c = Md(c);
  return a(b, b[c], d, e);
}, _emval_decref:xd, _emval_get_method_caller:(a, b, c) => {
  var d = Od(a, b), e = d.shift();
  a--;
  var f = Array(a);
  b = `methodCaller<(${d.map(g => g.name).join(", ")}) => ${e.name}>`;
  return Nd(pc(b, (g, h, n, m) => {
    for (var r = 0, w = 0; w < a; ++w) {
      f[w] = d[w].readValueFromPointer(m + r), r += d[w].argPackAdvance;
    }
    g = 1 === c ? Pd(h, f) : h.apply(g, f);
    return Jd(e, n, g);
  }));
}, _emval_get_module_property:a => {
  a = Md(a);
  return sc(k[a]);
}, _emval_get_property:(a, b) => {
  a = P(a);
  b = P(b);
  return sc(a[b]);
}, _emval_incref:a => {
  9 < a && (rc[a + 1] += 1);
}, _emval_new_array:() => sc([]), _emval_new_cstring:a => sc(Md(a)), _emval_new_object:() => sc({}), _emval_run_destructors:a => {
  var b = P(a);
  Pc(b);
  xd(a);
}, _emval_set_property:(a, b, c) => {
  a = P(a);
  b = P(b);
  c = P(c);
  a[b] = c;
}, _emval_take_value:(a, b) => {
  a = Fc(a, "_emval_take_value");
  a = a.readValueFromPointer(b);
  return sc(a);
}, _gmtime_js:function(a, b, c) {
  a = new Date(1000 * (b + 2097152 >>> 0 < 4194305 - !!a ? (a >>> 0) + 4294967296 * b : NaN));
  B[c >> 2] = a.getUTCSeconds();
  B[c + 4 >> 2] = a.getUTCMinutes();
  B[c + 8 >> 2] = a.getUTCHours();
  B[c + 12 >> 2] = a.getUTCDate();
  B[c + 16 >> 2] = a.getUTCMonth();
  B[c + 20 >> 2] = a.getUTCFullYear() - 1900;
  B[c + 24 >> 2] = a.getUTCDay();
  B[c + 28 >> 2] = (a.getTime() - Date.UTC(a.getUTCFullYear(), 0, 1, 0, 0, 0, 0)) / 864E5 | 0;
}, _localtime_js:function(a, b, c) {
  a = new Date(1000 * (b + 2097152 >>> 0 < 4194305 - !!a ? (a >>> 0) + 4294967296 * b : NaN));
  B[c >> 2] = a.getSeconds();
  B[c + 4 >> 2] = a.getMinutes();
  B[c + 8 >> 2] = a.getHours();
  B[c + 12 >> 2] = a.getDate();
  B[c + 16 >> 2] = a.getMonth();
  B[c + 20 >> 2] = a.getFullYear() - 1900;
  B[c + 24 >> 2] = a.getDay();
  B[c + 28 >> 2] = (Qd(a.getFullYear()) ? Rd : Sd)[a.getMonth()] + a.getDate() - 1 | 0;
  B[c + 36 >> 2] = -(60 * a.getTimezoneOffset());
  b = (new Date(a.getFullYear(), 6, 1)).getTimezoneOffset();
  var d = (new Date(a.getFullYear(), 0, 1)).getTimezoneOffset();
  B[c + 32 >> 2] = (b != d && a.getTimezoneOffset() == Math.min(d, b)) | 0;
}, _tzset_js:(a, b, c, d) => {
  var e = (new Date()).getFullYear(), f = new Date(e, 0, 1), g = new Date(e, 6, 1);
  e = f.getTimezoneOffset();
  var h = g.getTimezoneOffset();
  E[a >> 2] = 60 * Math.max(e, h);
  B[b >> 2] = Number(e != h);
  a = n => n.toLocaleTimeString(void 0, {hour12:!1, timeZoneName:"short"}).split(" ")[1];
  f = a(f);
  g = a(g);
  h < e ? (tb(f, A, c, 17), tb(g, A, d, 17)) : (tb(f, A, d, 17), tb(g, A, c, 17));
}, emscripten_asm_const_int:(a, b, c) => {
  Td.length = 0;
  for (var d; d = A[b++];) {
    var e = 105 != d;
    e &= 112 != d;
    c += e && c % 8 ? 4 : 0;
    Td.push(112 == d ? E[c >> 2] : 105 == d ? B[c >> 2] : Ja[c >> 3]);
    c += e ? 8 : 4;
  }
  return db[a](...Td);
}, emscripten_date_now:() => Date.now(), emscripten_get_now:() => performance.now(), emscripten_resize_heap:a => {
  var b = A.length;
  a >>>= 0;
  if (2147483648 < a) {
    return !1;
  }
  for (var c = 1; 4 >= c; c *= 2) {
    var d = b * (1 + 0.2 / c);
    d = Math.min(d, a + 100663296);
    var e = Math;
    d = Math.max(a, d);
    a: {
      e = (e.min.call(e, 2147483648, d + (65536 - d % 65536) % 65536) - Ca.buffer.byteLength + 65535) / 65536;
      try {
        Ca.grow(e);
        Ka();
        var f = 1;
        break a;
      } catch (g) {
      }
      f = void 0;
    }
    if (f) {
      return !0;
    }
  }
  return !1;
}, environ_get:(a, b) => {
  var c = 0;
  Wd().forEach((d, e) => {
    var f = b + c;
    e = E[a + 4 * e >> 2] = f;
    for (f = 0; f < d.length; ++f) {
      y[e++] = d.charCodeAt(f);
    }
    y[e] = 0;
    c += d.length + 1;
  });
  return 0;
}, environ_sizes_get:(a, b) => {
  var c = Wd();
  E[a >> 2] = c.length;
  var d = 0;
  c.forEach(e => d += e.length + 1);
  E[b >> 2] = d;
  return 0;
}, fd_close:function(a) {
  try {
    var b = Wb(a);
    if (null === b.U) {
      throw new M(8);
    }
    b.Ea && (b.Ea = null);
    try {
      b.l.close && b.l.close(b);
    } catch (c) {
      throw c;
    } finally {
      Jb[b.U] = null;
    }
    b.U = null;
    return 0;
  } catch (c) {
    if ("undefined" == typeof oc || "ErrnoError" !== c.name) {
      throw c;
    }
    return c.Y;
  }
}, fd_read:function(a, b, c, d) {
  try {
    a: {
      var e = Wb(a);
      a = b;
      for (var f, g = b = 0; g < c; g++) {
        var h = E[a >> 2], n = E[a + 4 >> 2];
        a += 8;
        var m = e, r = f, w = y;
        if (0 > n || 0 > r) {
          throw new M(28);
        }
        if (null === m.U) {
          throw new M(8);
        }
        if (1 === (m.flags & 2097155)) {
          throw new M(8);
        }
        if (16384 === (m.node.mode & 61440)) {
          throw new M(31);
        }
        if (!m.l.read) {
          throw new M(28);
        }
        var x = "undefined" != typeof r;
        if (!x) {
          r = m.position;
        } else if (!m.seekable) {
          throw new M(70);
        }
        var l = m.l.read(m, w, h, n, r);
        x || (m.position += l);
        var t = l;
        if (0 > t) {
          var q = -1;
          break a;
        }
        b += t;
        if (t < n) {
          break;
        }
        "undefined" != typeof f && (f += t);
      }
      q = b;
    }
    E[d >> 2] = q;
    return 0;
  } catch (C) {
    if ("undefined" == typeof oc || "ErrnoError" !== C.name) {
      throw C;
    }
    return C.Y;
  }
}, fd_seek:function(a, b, c, d, e) {
  b = c + 2097152 >>> 0 < 4194305 - !!b ? (b >>> 0) + 4294967296 * c : NaN;
  try {
    if (isNaN(b)) {
      return 61;
    }
    var f = Wb(a);
    kc(f, b, d);
    $a = [f.position >>> 0, (Za = f.position, 1.0 <= +Math.abs(Za) ? 0.0 < Za ? +Math.floor(Za / 4294967296.0) >>> 0 : ~~+Math.ceil((Za - +(~~Za >>> 0)) / 4294967296.0) >>> 0 : 0)];
    B[e >> 2] = $a[0];
    B[e + 4 >> 2] = $a[1];
    f.Ea && 0 === b && 0 === d && (f.Ea = null);
    return 0;
  } catch (g) {
    if ("undefined" == typeof oc || "ErrnoError" !== g.name) {
      throw g;
    }
    return g.Y;
  }
}, fd_write:function(a, b, c, d) {
  try {
    a: {
      var e = Wb(a);
      a = b;
      for (var f, g = b = 0; g < c; g++) {
        var h = E[a >> 2], n = E[a + 4 >> 2];
        a += 8;
        var m = e, r = h, w = n, x = f, l = y;
        if (0 > w || 0 > x) {
          throw new M(28);
        }
        if (null === m.U) {
          throw new M(8);
        }
        if (0 === (m.flags & 2097155)) {
          throw new M(8);
        }
        if (16384 === (m.node.mode & 61440)) {
          throw new M(31);
        }
        if (!m.l.write) {
          throw new M(28);
        }
        m.seekable && m.flags & 1024 && kc(m, 0, 2);
        var t = "undefined" != typeof x;
        if (!t) {
          x = m.position;
        } else if (!m.seekable) {
          throw new M(70);
        }
        var q = m.l.write(m, l, r, w, x, void 0);
        t || (m.position += q);
        var C = q;
        if (0 > C) {
          var H = -1;
          break a;
        }
        b += C;
        "undefined" != typeof f && (f += C);
      }
      H = b;
    }
    E[d >> 2] = H;
    return 0;
  } catch (v) {
    if ("undefined" == typeof oc || "ErrnoError" !== v.name) {
      throw v;
    }
    return v.Y;
  }
}, invoke_vii:ce, isWindowsBrowser:function() {
  return -1 < navigator.platform.indexOf("Win");
}, strftime:Zd, strftime_l:(a, b, c, d) => Zd(a, b, c, d), wasm_start_image_decode:function(a, b, c) {
  b = k.HEAP8.subarray(b, b + c);
  c = new Uint8Array(c);
  c.set(b);
  createImageBitmap(new Blob([c])).then(function(d) {
    var e = (new OffscreenCanvas(d.width, d.height)).getContext("2d");
    e.drawImage(d, 0, 0);
    e = e.getImageData(0, 0, d.width, d.height);
    var f = e.data.length, g = k.vb(f);
    k.lc.set(e.data, g);
    k.nc(a, d.width, d.height, g, f);
  }).catch(function(d) {
    d = d.message || "decode failed";
    var e = k.Ec(d) + 1, f = k.vb(e);
    k.Jc(d, f, e);
    k.oc(a, f);
    k.mc(f);
  });
}}, Y = function() {
  function a(c) {
    Y = c.exports;
    Ca = Y.memory;
    Ka();
    jd = Y.__indirect_function_table;
    Ma.unshift(Y.__wasm_call_ctors);
    Pa--;
    k.monitorRunDependencies?.(Pa);
    0 == Pa && (null !== Qa && (clearInterval(Qa), Qa = null), Ra && (c = Ra, Ra = null, c()));
    return Y;
  }
  var b = {env:de, wasi_snapshot_preview1:de,};
  Pa++;
  k.monitorRunDependencies?.(Pa);
  if (k.instantiateWasm) {
    try {
      return k.instantiateWasm(b, a);
    } catch (c) {
      Aa(`Module.instantiateWasm callback failed with error: ${c}`), ca(c);
    }
  }
  Ua ||= Ta("canvas_advanced.wasm") ? "canvas_advanced.wasm" : k.locateFile ? k.locateFile("canvas_advanced.wasm", ta) : ta + "canvas_advanced.wasm";
  Ya(b, function(c) {
    a(c.instance);
  }).catch(ca);
  return {};
}(), Dc = a => (Dc = Y.free)(a), be = a => (be = Y.malloc)(a), Cc = a => (Cc = Y.__getTypeName)(a);
k._wasm_image_decode_complete = (a, b, c, d, e) => (k._wasm_image_decode_complete = Y.wasm_image_decode_complete)(a, b, c, d, e);
k._wasm_image_decode_error = (a, b) => (k._wasm_image_decode_error = Y.wasm_image_decode_error)(a, b);
var ab = k._ma_device__on_notification_unlocked = a => (ab = k._ma_device__on_notification_unlocked = Y.ma_device__on_notification_unlocked)(a);
k._ma_malloc_emscripten = (a, b) => (k._ma_malloc_emscripten = Y.ma_malloc_emscripten)(a, b);
k._ma_free_emscripten = (a, b) => (k._ma_free_emscripten = Y.ma_free_emscripten)(a, b);
var bb = k._ma_device_process_pcm_frames_capture__webaudio = (a, b, c) => (bb = k._ma_device_process_pcm_frames_capture__webaudio = Y.ma_device_process_pcm_frames_capture__webaudio)(a, b, c), cb = k._ma_device_process_pcm_frames_playback__webaudio = (a, b, c) => (cb = k._ma_device_process_pcm_frames_playback__webaudio = Y.ma_device_process_pcm_frames_playback__webaudio)(a, b, c), ee = (a, b) => (ee = Y.setThrew)(a, b), fe = a => (fe = Y._emscripten_stack_restore)(a), ge = () => (ge = Y.emscripten_stack_get_current)();
k.dynCall_iiji = (a, b, c, d, e) => (k.dynCall_iiji = Y.dynCall_iiji)(a, b, c, d, e);
k.dynCall_jiji = (a, b, c, d, e) => (k.dynCall_jiji = Y.dynCall_jiji)(a, b, c, d, e);
k.dynCall_iiiji = (a, b, c, d, e, f) => (k.dynCall_iiiji = Y.dynCall_iiiji)(a, b, c, d, e, f);
k.dynCall_iij = (a, b, c, d) => (k.dynCall_iij = Y.dynCall_iij)(a, b, c, d);
k.dynCall_jii = (a, b, c) => (k.dynCall_jii = Y.dynCall_jii)(a, b, c);
k.dynCall_viijii = (a, b, c, d, e, f, g) => (k.dynCall_viijii = Y.dynCall_viijii)(a, b, c, d, e, f, g);
k.dynCall_iiiiij = (a, b, c, d, e, f, g) => (k.dynCall_iiiiij = Y.dynCall_iiiiij)(a, b, c, d, e, f, g);
k.dynCall_iiiiijj = (a, b, c, d, e, f, g, h, n) => (k.dynCall_iiiiijj = Y.dynCall_iiiiijj)(a, b, c, d, e, f, g, h, n);
k.dynCall_iiiiiijj = (a, b, c, d, e, f, g, h, n, m) => (k.dynCall_iiiiiijj = Y.dynCall_iiiiiijj)(a, b, c, d, e, f, g, h, n, m);
function ce(a, b, c) {
  var d = ge();
  try {
    kd(a)(b, c);
  } catch (e) {
    fe(d);
    if (e !== e + 0) {
      throw e;
    }
    ee(1, 0);
  }
}
var he;
Ra = function ie() {
  he || je();
  he || (Ra = ie);
};
function je() {
  function a() {
    if (!he && (he = !0, k.calledRun = !0, !Da)) {
      k.noFSInit || lc || (lc = !0, k.stdin = k.stdin, k.stdout = k.stdout, k.stderr = k.stderr, k.stdin ? mc("stdin", k.stdin) : hc("/dev/tty", "/dev/stdin"), k.stdout ? mc("stdout", null, k.stdout) : hc("/dev/tty", "/dev/stdout"), k.stderr ? mc("stderr", null, k.stderr) : hc("/dev/tty1", "/dev/stderr"), ic("/dev/stdin", 0), ic("/dev/stdout", 1), ic("/dev/stderr", 1));
      Mb = !1;
      eb(Ma);
      ba(k);
      if (k.onRuntimeInitialized) {
        k.onRuntimeInitialized();
      }
      if (k.postRun) {
        for ("function" == typeof k.postRun && (k.postRun = [k.postRun]); k.postRun.length;) {
          var b = k.postRun.shift();
          Na.unshift(b);
        }
      }
      eb(Na);
    }
  }
  if (!(0 < Pa)) {
    if (k.preRun) {
      for ("function" == typeof k.preRun && (k.preRun = [k.preRun]); k.preRun.length;) {
        Oa();
      }
    }
    eb(La);
    0 < Pa || (k.setStatus ? (k.setStatus("Running..."), setTimeout(function() {
      setTimeout(function() {
        k.setStatus("");
      }, 1);
      a();
    }, 1)) : a());
  }
}
if (k.preInit) {
  for ("function" == typeof k.preInit && (k.preInit = [k.preInit]); 0 < k.preInit.length;) {
    k.preInit.pop()();
  }
}
je();
moduleRtn = da;



  return moduleRtn;
}
);
})();
module.exports = Rive;
