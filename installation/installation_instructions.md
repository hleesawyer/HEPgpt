### Installing and preparing the hepgpt environment and/or miniconda and nim based conda environments from bash script
NOTE: If there is an error or issues during the installation, it is not impossible to remove anaconda/miniconda and all its environments to install everything fresh.
- the removal process:
rm -rf ~/anaconda3 
rm -rf ~/miniconda3
sed -i '/anaconda3/d' ~/.bashrc # remove the export from bashrc
sed -i '/miniconda3/d' ~/.bashrc # remove the export from bashrc


##### 0. If not installed, download and install miniconda using the following commands in a bash file
touch hepgpt_env_install.sh
chmod 777 hepgpt_env_install.sh

### hepgpt_env_install.sh (copy and paste all this inside the file then execute it with  ./hepgpt_env_install.sh; consider using requirements.txt in the future)
################################### hepgpt_env_install.sh ####################################
##### 1. Do a search for and download the appropriate miniconda install
##### Uncomment these if miniconda is not installed and you are pointed to the directory with the miniconda.sh file
##### chmod 777 <miniconda_sh_path.sh>
##### ./<miniconda_sh_path.sh>

##### 2. create anaconda environment: "conda create --name envname"
##### (Uncomment this line if the hepgpt environment does not exist in anaconda)
##### conda create --name hepgpt

##### 3. activate the envrionment (everytime you use nim or the project packages): "conda activate envname"
conda activate hepgpt

##### 4. Export all the necessary miniconda bin locations --actually, maybe don't do this. i broke my conda before b/c of path i think
export PATH=/home/wrkn/miniconda3/envs/hepgpt/bin:$PATH
export PATH=/home/wrkn/miniconda3/bin:$PATH

##### Install the packages and echo the results when it completes, you may want to install ethernet cable for this
##### 5. install nim to conda: "conda install -c conda-forge nim" 
conda install -c conda-forge nim -y
echo "nim -"

##### 6. export the nim binaries from its anaconda location using the following command:
export PATH=/home/wrkn/miniconda3/envs/hepgpt/bin:$PATH

nimble install nimpy -y
echo "nimpy -"

conda install -c conda-forge mlflow -y
echo "mlflow -"

conda install -c conda-forge tensorflow -y
echo "tensorflow -"

conda install pandas -y
echo "pandas -"

conda install matplotlib -y
echo "matplotlib -"

conda install numpy -y
echo "numpy -"

conda install seaborn -y
echo "seaborn -"

conda install -c conda-forge nltk -y
echo "nltk -"

# conda config --add channels conda-forge -y
# echo "channel1 -"

# conda config --set channel_priority strict -y
# echo "channel2 -"

# conda install uproot-browser -y
conda install -c conda-forge uproot-browser -y
echo "uproot-browser -"

conda install -c conda-forge root -y
echo "root -"

############################################################
### ADDITIONAL INFORMATION

- The installation proceeded smoothly until the add channel and uproot-browser installations. I suspect that the add channel commands could have broken installing things with conda before I had to wipe everything. In the future, 

- Scikit-HEP's uproot:
https://masonproffitt.github.io/uproot-tutorial/aio/index.html


- Scikit-HEP's uproot-browser:
https://github.com/conda-forge/uproot-browser-feedstock
https://github.com/scikit-hep/uproot-browser  (gives examples of use)
conda install -c conda-forge uproot-browser

- mlflow


- nltk


- tensorflow or tensorflow-gpu
conda install -c anaconda tensorflow-gpu

- cuda
conda install -c anaconda cudatoolkit
conda install -c nvidia cuda-toolkit

- pandas
conda install -c anaconda pandas

- numpy
conda install -c anaconda numpy

- seaborn
conda install -c anaconda seaborn