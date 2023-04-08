echo "mlflow start..."
conda install -c conda-forge mlflow -y
echo "mlflow complete."

echo "tensorflow start..."
conda install -c conda-forge tensorflow -y
echo "tensorflow install complete."

echo "pandas start..."
conda install pandas -y
echo "pandas install complete."

echo "matplotlib start..."
conda install matplotlib -y
echo "matplotlib install complete."

echo "numpy start..."
conda install numpy -y
echo "numpy install complete."

echo "seaborn start..."
conda install seaborn -y
echo "seaborn install complete."

echo "nltk start..."
conda install -c conda-forge nltk -y
echo "nltk install complete."

echo "channel 1 command start..."
conda config --add channels conda-forge -y
echo "channel1 command finished."
echo "channel 2 command start..."
conda config --set channel_priority strict -y
echo "channel2 command finished."
echo "uproot-browser start..."
conda install uproot-browser -y
echo "uproot-browser install complete."

echo "root start..."
conda install -c conda-forge root -y
echo "root install complete."