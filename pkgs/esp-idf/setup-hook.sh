# Export the necessary environment variables to use ESP-IDF.

addIdfEnvVars() {
    # Crude way to detect if $1 is the ESP-IDF derivation.
    if [ -e "$1/tools/idf.py" ]; then
        export IDF_PATH="$1"
        export IDF_TOOLS_PATH="$IDF_PATH/tools"
        export IDF_PYTHON_CHECK_CONSTRAINTS=no
        # Set the python env path to the target of the python-env link
        # This avoids a warning when idf.py checks that the python interpreter
        # matches the env path
        export IDF_PYTHON_ENV_PATH=$(readlink "$IDF_PATH/python-env")
        addToSearchPath PATH "$IDF_TOOLS_PATH"
    fi
}

addEnvHooks "$hostOffset" addIdfEnvVars
