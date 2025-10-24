"""Parser module to parse gear config.json."""

from typing import Tuple
import logging
from flywheel_gear_toolkit import GearToolkitContext
import subprocess as sp
from zipfile import ZipFile
import os

log = logging.getLogger(__name__)

# This function mainly parses gear_context's config.json file and returns relevant
# inputs and options.
def parse_config(
    gear_context: GearToolkitContext,
) -> Tuple[str, str]:
    """[Summary].

    Returns:
        [type]: [description]
    """

    session_id = gear_context.client.get_container(gear_context.destination["id"])["parents"]["session"]
    session = gear_context.client.get_session(session_id)
    log.info("Using subject: %s, %s", session.subject.label, session.label)

    gear_options = {
        "output-dir": gear_context.output_dir,
        "destination-id": gear_context.destination["id"],
        "work-dir": gear_context.work_dir,
        "client": gear_context.client,
        "environ": os.environ,
        "debug": gear_context.config.get("debug")
    }

    # unzip input files
    if "zip" in gear_context.get_input_path("sample_data"):
        rc, path = unzip_inputs(gear_options, gear_context.get_input_path("sample_data"))
    else:
        path = gear_context.get_input_path("sample_data")
    log.info("Inputs file path, %s", "\n".join(path))

    return gear_options, path


def unzip_inputs(gear_options, zip_filename):
    """
    unzip_inputs unzips the contents of zipped gear output into the working
    directory.
    Args:
        gear_options: The gear context object
            containing the 'gear_dict' dictionary attribute with key/value,
            'gear-dry-run': boolean to enact a dry run for debugging
        zip_filename (string): The file to be unzipped
    """
    rc = 0
    outpath=[]
    # use linux "unzip" methods in shell in case symbolic links exist
    log.info("Unzipping file, %s", zip_filename)
    cmd = "unzip -qq -o " + zip_filename + " -d " + str(gear_options["work-dir"])
    execute_shell(cmd, cwd=gear_options["work-dir"])

    # if unzipped directory is a destination id - move all outputs one level up
    with ZipFile(zip_filename, "r") as f:
        top = [item.split('/')[0] for item in f.namelist()]
        top1 = [item.split('/')[1] for item in f.namelist()]

    log.info("Done unzipping.")

    if len(top[0]) == 24:
        # directory starts with flywheel destination id - obscure this for now...

        cmd = "mv "+top[0]+'/* . '
        rc = execute_shell(cmd, cwd=gear_options["work-dir"])
        if rc > 0:
            cmd = "cp -R " + top[0] + '/* . '
            execute_shell(cmd, cwd=gear_options["work-dir"])

        cmd = 'rm -R ' + top[0]
        rc = execute_shell(cmd, cwd=gear_options["work-dir"])

        for i in set(top1):
            outpath.append(os.path.join(gear_options["work-dir"], i))

        # get previous gear info
        gear_options["preproc_gear"] = gear_options["client"].get_analysis(top[0])
    else:
        outpath = os.path.join(gear_options["work-dir"], top[0])

    return rc, outpath


def execute_shell(cmd, dryrun=False, cwd=os.getcwd()):
    log.info("\n %s", cmd)
    if not dryrun:
        terminal = sp.Popen(
            cmd,
            shell=True,
            stdout=sp.PIPE,
            stderr=sp.PIPE,
            universal_newlines=True,
            cwd=cwd
        )
        stdout, stderr = terminal.communicate()
        returnCode = terminal.poll()
        log.debug("\n %s", stdout)
        log.debug("\n %s", stderr)

        if stderr:
            log.warning("Error. \n%s\n%s", stdout, stderr)
            returnCode = 1
        return returnCode