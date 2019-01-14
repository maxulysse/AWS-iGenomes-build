FROM nfcore/base:latest

LABEL \
  authors="maxime.garcia@scilifelab.se" \
  description="Image with tools to build AWS iGenomes references" \
	maintainer="Maxime Garcia <maxime.garcia@scilifelab.se>"

COPY environment.yml /
RUN conda update -n base -c defaults conda  \
  && conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/aws-igenomes-build-alpha/bin:$PATH
