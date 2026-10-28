"""Prepare a save-free game copy for the authored plot's runtime regression."""
import argparse
import subprocess
import sys
from pathlib import Path


def main():
    """Reuse the isolated build setup, replacing only its test driver."""
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ending-only', action='store_true', help='Debug the directed finale before the complete run')
    args = parser.parse_args()
    work = root / '.temp/plot_implementation/smoke'
    subprocess.run([sys.executable, str(root / 'tools/prepare_theme_smoke.py'),
                    '--work-dir', str(work)], check=True)
    target = work / 'project/scripts/scriptThemeSmoke/scriptThemeSmoke.gml'
    driver = (root / 'tools/plot_smoke.gml').read_text()
    if args.ending_only:
        driver = driver.replace('self.stage = 0', 'self.stage = 11', 1)
    target.write_text(driver)
    print(f'Plot smoke: {work}; production save writes disabled.')


if __name__ == '__main__':
    main()
