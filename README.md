# PX_Gather_Logs.sh

## Description
Collects logs and other information related to Portworx/PX Backup.

## Usage
### Passing Inputs as Parameters
#### For Portworx:
```bash
PX_Gather_Logs.sh -n <Portworx namespace> -c <k8s cli> -o PX
```
Example:
```bash
PX_Gather_Logs.sh -n portworx -c kubectl -o PX
```

#### For PX Backup:
```bash
PX_Gather_Logs.sh -n <Portworx Backup namespace> -c <k8s cli> -o PXB
```
Example:
```bash
PX_Gather_Logs.sh -n px-backup -c oc -o PXB
```

### Without Parameters
If no parameters are passed, the script will prompt for input.

### Execute Using Curl
You can download and execute the script directly from GitHub using the following command:
```bash
curl -sL https://github.com/your-repo/PX_Gather_Logs.sh | bash
```

---

**Note:**
Ensure that the necessary permissions are in place to collect logs and execute commands in the specified namespace.
