#install PFAC

import os
import logging
import shutil

# shutil.rmtree('/folder_name')

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

logging.basicConfig(level=logging.INFO)

PFAC_COMMON="aho-corasick/PFAC/common.mk"
PFAC_MAKEFILE="aho-corasick/PFAC/Makefile"
PFAC_KERNEL="aho-corasick/PFAC/PFAC_kernel.cu"
PFAC_TABLE="aho-corasick/PFAC/PFAC_reorder_Table.cpp"

logger = logging.getLogger('install_dependencies')


def install_pfac():
    s = os.system("git --version")
    if(s):
        logger.warning(bcolors.FAIL + "Git not found" + bcolors.ENDC)
        return

    try:
        if(os.path.isdir("PFAC")):
            logger.info(f"PFAC install directory exists, removing...")
            shutil.rmtree("PFAC",ignore_errors=True)

        logger.info(f"Creating PFAC directory")
        if(os.system("git clone https://github.com/pfac-lib/PFAC")):
            raise Exception
        shutil.copyfile(PFAC_COMMON,"PFAC/PFAC/common.mk")
        shutil.copyfile(PFAC_MAKEFILE,"PFAC/PFAC/src/Makefile")
        shutil.copyfile(PFAC_TABLE,"PFAC/PFAC/src/PFAC_reorder_Table.cpp")
        shutil.copyfile(PFAC_KERNEL,"PFAC/PFAC/src/PFAC_kernel.cu")
        os.chdir("PFAC/PFAC")
        logger.info(f"Moved to {os.getcwd()}")
        if(os.system("make")):
            raise Exception
        PFAC_LIB_ROOT = os.getcwd()
        logger.info(f"{PFAC_LIB_ROOT}")
        ld_path = f'LD_LIBRARY_PATH={PFAC_LIB_ROOT}/lib:$LD_LIBRARY_PATH'
        logger.info(f"export {ld_path}")
        os.chdir("bin")
        if(not os.system(f"export {ld_path} && ./simple_example.exe")):
            logger.info(f"{bcolors.OKGREEN}TEST PASSED PFAC SUCCESFULLY INSTALLED{bcolors.ENDC}")
        # os.system(f"echo $LD_LIBRARY_PATH")
        # os.system("bin/simple_example.exe")
        return ld_path


    except FileNotFoundError as ex:
        logger.warning(bcolors.FAIL + f"{ex}" + bcolors.ENDC)
    except Exception:
        logger.warning(bcolors.FAIL + f"Installing failed check out the logs" + bcolors.ENDC)

def install_jitify():
    os.system("git clone https://github.com/NVIDIA/jitify")


if __name__ == "__main__":
    pwd = os.getcwd()
    logger.info("Installing dependencies...")
    logger.info("Installing PFAC")
    print(f"Add ${install_pfac()} to bashrc")
    os.chdir(pwd)
    install_jitify()
