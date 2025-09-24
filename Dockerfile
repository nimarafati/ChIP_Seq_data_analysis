# ChIP-Seq Data Analysis Container
FROM continuumio/miniconda3:latest

LABEL maintainer="ChIP-Seq Analysis Team"
LABEL description="Container for ChIP-Seq data analysis workflow"
LABEL version="1.0"

# Set working directory
WORKDIR /app

# Update conda and install mamba for faster package resolution
RUN conda update -n base -c defaults conda && \
    conda install -n base -c conda-forge mamba

# Copy environment file
COPY environment.yml .

# Create conda environment from yaml file
RUN mamba env create -f environment.yml

# Make RUN commands use the new environment
SHELL ["conda", "run", "-n", "chipseq-analysis", "/bin/bash", "-c"]

# Install additional R packages that might not be available in conda
RUN conda run -n chipseq-analysis R -e "install.packages(c('BiocManager'), repos='https://cran.rstudio.com/')" && \
    conda run -n chipseq-analysis R -e "BiocManager::install(c('ChIPseeker', 'GenomicFeatures', 'TxDb.Hsapiens.UCSC.hg38.knownGene'))"

# Create necessary directories
RUN mkdir -p /app/data /app/results /app/report

# Copy project files
COPY report/ /app/report/
COPY README.md /app/

# Set up permissions
RUN chmod -R 755 /app

# Create a script to activate environment and start analysis
RUN echo '#!/bin/bash' > /app/start_analysis.sh && \
    echo 'source activate chipseq-analysis' >> /app/start_analysis.sh && \
    echo 'cd /app' >> /app/start_analysis.sh && \
    echo 'echo "ChIP-Seq Analysis Environment Ready!"' >> /app/start_analysis.sh && \
    echo 'echo "Available commands:"' >> /app/start_analysis.sh && \
    echo 'echo "  - R: Start R console"' >> /app/start_analysis.sh && \
    echo 'echo "  - jupyter notebook: Start Jupyter server"' >> /app/start_analysis.sh && \
    echo 'echo "  - bash: Start bash shell"' >> /app/start_analysis.sh && \
    echo '/bin/bash' >> /app/start_analysis.sh && \
    chmod +x /app/start_analysis.sh

# Expose port for Jupyter notebook
EXPOSE 8888

# Set default command
CMD ["/app/start_analysis.sh"]

# Environment variables
ENV PATH /opt/conda/envs/chipseq-analysis/bin:$PATH
ENV CONDA_DEFAULT_ENV chipseq-analysis