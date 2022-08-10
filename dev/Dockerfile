ARG BASE_CONTAINER=jupyter/scipy-notebook

FROM ${BASE_CONTAINER}

USER ${NB_UID}

RUN pip install --quiet --no-cache-dir \
    'divewidgets' \
    'divemathjax3' \
    'divemarkdownit' \
    && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}"

WORKDIR "${HOME}"

CMD ["start-notebook.sh", "--LabApp.collaborative=True"]