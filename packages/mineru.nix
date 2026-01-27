{ lib
, pkgs
, python3Packages
, fetchurl
, torch ? null
, extras ? [ ]
}:

let
  py = python3Packages;
  has = name: builtins.hasAttr name py;
  opt = name: lib.optional (has name) py.${name};

  torchPkg =
    if torch != null then torch
    else if has "torch" then py.torch
    else null;

  baseDeps = lib.flatten [
    (opt "boto3")
    (opt "click")
    (opt "loguru")
    (opt "numpy")
    (opt "pdfminer-six")
    (opt "tqdm")
    (opt "requests")
    (opt "httpx")
    (opt "pillow")
    (opt "pypdfium2")
    (opt "pypdf")
    (opt "reportlab")
    (opt "pdftext")
    (opt "modelscope")
    (opt "huggingface-hub")
    (opt "json-repair")
    (opt "opencv-python")
    (opt "opencv4")
    (opt "fast-langdetect")
    (opt "scikit-image")
    (opt "openai")
    (opt "beautifulsoup4")
    (opt "magika")
    (opt "mineru-vl-utils")
    (opt "qwen-vl-utils")
  ];

  vlmDeps = lib.flatten [
    (lib.optional (torchPkg != null) torchPkg)
    (opt "transformers")
    (opt "accelerate")
  ];

  vllmDeps = opt "vllm";
  lmdeployDeps = opt "lmdeploy";
  mlxDeps = opt "mlx-vlm";

  pipelineDeps = lib.flatten [
    (opt "matplotlib")
    (opt "ultralytics")
    (opt "doclayout_yolo")
    (opt "dill")
    (opt "pyyaml")
    (opt "ftfy")
    (opt "shapely")
    (opt "pyclipper")
    (opt "omegaconf")
    (lib.optional (torchPkg != null) torchPkg)
    (opt "torchvision")
    (opt "transformers")
    (opt "onnxruntime")
  ];

  apiDeps = lib.flatten [
    (opt "fastapi")
    (opt "python-multipart")
    (opt "uvicorn")
  ];

  gradioDeps = lib.flatten [
    (opt "gradio")
    (opt "gradio-pdf")
  ];

  use = name: builtins.elem name extras;
  selectedExtras = lib.flatten (
    (lib.optional (use "vlm") vlmDeps)
    ++ (lib.optional (use "vllm") vllmDeps)
    ++ (lib.optional (use "lmdeploy") lmdeployDeps)
    ++ (lib.optional (use "mlx") mlxDeps)
    ++ (lib.optional (use "pipeline") pipelineDeps)
    ++ (lib.optional (use "api") apiDeps)
    ++ (lib.optional (use "gradio") gradioDeps)
  );
in
python3Packages.buildPythonApplication rec {
  pname = "mineru";
  version = "2.7.1";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/py3/m/mineru/mineru-${version}-py3-none-any.whl";
    sha256 = "3c144149f2749a79be240833c392216ddd69c1516de162b29dbaddbc0ce38f73";
  };

  propagatedBuildInputs = lib.unique (baseDeps ++ selectedExtras);
  nativeBuildInputs = [ pkgs.ninja ];
  dontBuild = true;
  buildPhase = ":";

  pythonImportsCheck = [ "mineru" ];

  meta = with lib; {
    description = "MinerU CLI (Nix package)";
    homepage = "https://pypi.org/project/mineru/";
    license = licenses.agpl3Only;
  };
}
