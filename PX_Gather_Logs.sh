#!/bin/bash
# ================================================================
# Script: PX_Gather_Logs.sh
# Description: Collects logs and other ifnormation related to portworx/PX Backup.
# Usage:
# - We can pass the inputs as parameters like below
#   For Portworx : PX_Gather_Logs.sh -n <Portworx namespace> -c <k8s cli> -o PX
#       Example: PX_Gather_Logs.sh -n portworx -c kubectl -o PX
#   For PX Backup: PX_Gather_Logs.sh -n <Portworx Backup namespace> -c <k8s cli> -o PXB
#       Example: PX_Gather_Logs.sh -n px-backup -c oc -o PXB
# - If there are no parameters passed, shell will promt for input
#
#
# ================================================================

# Function to display usage
usage() {
  echo "Usage: $0 [-n <namespace>] [-c <cli>] [-o <option>]"
  echo "  -n <namespace> : Kubernetes namespace"
  echo "  -c <cli>       : CLI tool to use (oc/kubectl)"
  echo "  -o <option>    : Operation option (PX/PXB)"
  exit 1
}

# Parse command-line arguments
while getopts "n:c:o:" opt; do
  case $opt in
    n) namespace="$OPTARG" ;;
    c) cli="$OPTARG" ;;
    o) option="$OPTARG" ;;
    *) usage ;;
  esac
done

# Prompt for namespace if not provided
if [[ -z "$namespace" ]]; then
  read -p "Enter the namespace: " namespace
  if [[ -z "$namespace" ]]; then
    echo "Error: Namespace cannot be empty."
    exit 1
  fi
fi

# Prompt for k8s CLI  if not provided
if [[ -z "$cli" ]]; then
  read -p "Enter the k8s CLI  (oc/kubectl): " cli
  if [[ "$cli" != "oc" && "$cli" != "kubectl" ]]; then
    echo "Error: Invalid k8s CLI . Choose either 'oc' or 'kubectl'."
    exit 1
  fi
fi

# Prompt for option if not provided
if [[ -z "$option" ]]; then
  read -p "Choose an option (PX/PXB) (Enter PX for Portworx Enterprise/CSI, Enter PXB for PX Backup): " option
  if [[ "$option" != "PX" && "$option" != "PXB" ]]; then
    echo "Error: Invalid option. Choose either 'PX' or 'PXB'."
    exit 1
  fi
fi


# Confirm inputs
echo "Namespace: $namespace"
echo "CLI tool: $cli"
echo "option: $option"
# Set commands based on the chosen option
if [[ "$option" == "PX" ]]; then
  admin_ns=$($cli -n $namespace get stc -o yaml|grep admin-namespace|cut -d ":" -f2|tr -d " ")
  admin_ns="${admin_ns:-kube-system}"

  commands=(
    "get pods -o wide -n $namespace"
    "get pods -o wide -n $namespace -o yaml"
    "describe pods -n $namespace"
    "get nodes -o wide -n $namespace"
    "get nodes -o wide -n $namespace -o yaml"
    "describe nodes -n $namespace"
    "get events -A"
    "get stc -o yaml -n $namespace"
    "describe stc -n $namespace"
    "get deploy -o wide -n $namespace"
    "get deploy -o wide -n $namespace -o yaml"
    "describe deploy -n $namespace"
    "get volumeattachments -A "
    "get csidrivers"
    "get csinodes"
    "get csinodes -o yaml"
    "get all -o wide -n $namespace"
    "describe all -n $namespace"
    "get all -o wide -n $namespace -o yaml"
    "get configmaps -n $namespace"
    "describe namespace $namespace"
    "get namespace $namespace -o yaml"
    "get pvc -n $namespace"
    "get pvc -n $namespace -o yaml"
    "get secret -n $namespace"
    "get sc"
    "get sc -o yaml"
    "get pvc -A"
    "get pv"
  )
  output_files=(
    "k8s_px/px_pods.txt"
    "k8s_px/px_pods.yaml"
    "k8s_px/px_pods_desc.txt"
    "k8s_px/k8s_nodes.txt"
    "k8s_oth/k8s_nodes.yaml"
    "k8s_oth/k8s_nodes_desc.txt"
    "k8s_oth/k8s_events_all.txt"
    "k8s_px/px_stc.yaml"
    "k8s_px/px_stc_desc.txt"
    "k8s_px/px_deploy.txt"
    "k8s_px/px_deploy.yaml"
    "k8s_px/px_deploy_desc.txt"
    "k8s_oth/k8s_volumeattachments_all.txt"
    "k8s_oth/csidrivers.txt"
    "k8s_oth/csinodes.txt"
    "k8s_oth/csinodes.yaml"
    "k8s_px/px_all.txt"
    "k8s_px/px_all_desc.txt"
    "k8s_px/px_all.yaml"
    "k8s_px/px_cm.txt"
    "k8s_px/px_ns_dec.txt"
    "k8s_px/px_ns_dec.yaml"
    "k8s_px/px_pvc.txt"
    "k8s_px/px_pvc.yaml"
    "k8s_px/px_secret_list.txt"
    "k8s_oth/sc.txt"
    "k8s_oth/sc.yaml"
    "k8s_oth/pvc_list.txt"
    "k8s_oth/pv_list.txt"

  )
  pxctl_commands=(
    "status"
    "status -j"
    "cluster provision-status"
    "license list"
    "cluster options list"
    "cluster options list -j"
    "sv k m"
    "alerts show"
    "cloudsnap status"
    "cloudsnap status -j"
    "cd list"
    "cred list"
    "volume list -v"
    "volume list -s"
    "cluster list"
  )
  pxctl_output_files=(
    "px_out/pxctl_status.txt"
    "px_out/pxctl_status.json"
    "px_out/pxctl_cluster_provision_status.txt"
    "px_out/pxctl_license_list.txt"
    "px_out/pxctl_cluster_options.txt"
    "px_out/pxctl_cluster_options.json"
    "px_out/pxctl_kvdb_members.txt"
    "px_out/pxctl_alerts_show.txt"
    "px_out/pxctl_cs_status.txt"
    "px_out/pxctl_cs_status.json"
    "px_out/pxctl_cd_list.txt"
    "px_out/pxct_cred_list.txt"
    "px_out/px_volume_list.txt"
    "px_out/px_volume_snapshot.txt"
    "px_out/c_list.txt"
 
 )

  log_labels=(
    "name=autopilot"
    "name=portworx-api"
    "name=portworx-operator"
    "app=px-csi-driver"
    "name=stork"
    "name=stork-scheduler"
    "name=portworx-pvc-controller"
    "role=px-telemetry-registration"
    "name=px-telemetry-phonehome"
    "app=px-plugin"
    "name=px-plugin-proxy"
  )

  oth_commands=(
    "$cli -n kube-system get cm $($cli -n kube-system get cm|grep px-bootstrap|awk '{print $1}') -o yaml"
    "$cli -n kube-system get cm $($cli -n kube-system get cm|grep px-cloud-drive|awk '{print $1}') -o yaml"

  )
  oth_output_files=(
    "k8s_px/px-bootstrap.yaml"
    "k8s_px/px-cloud-drive.yaml"

  )
  migration_commands=(
    "get clusterpair -n $admin_ns"
    "describe clusterpair -n $admin_ns "
    "get clusterpair -n $admin_ns -o yaml"
    "get migrations -n $admin_ns"
    "get describe migrations -n $admin_ns"
    "get migrations -n $admin_ns -o yaml"
    "get migrationschedule -n $admin_ns"
    "get migrationschedule -n $admin_ns -o yaml"
    "get schedulepolicies"
    "get schedulepolicies -o yaml"
  )
   migration_ouput=(
    "migration/clusterpair.txt"
    "migration/clusterpair_desc.txt"
    "migration/clusterpair.yaml"
    "migration/migrations.txt"
    "migration/migrations_desc.txt"
    "migration/migrations.yaml"
    "migration/migrationschedule.txt"
    "migration/migrationschedule.yaml"
    "migration/schedulepolicies.txt"
    "migration/schedulepolicies.yaml"
  )

  pxcmd="exec -it service/portworx-service -- /opt/pwx/bin/pxctl"
  main_dir="PX_${namespace}_outputs_$(date +%Y%m%d_%s)"
  output_dir="/tmp/${main_dir}"
  sub_dir=(${output_dir}/logs ${output_dir}/px_out ${output_dir}/k8s_px ${output_dir}/k8s_oth ${output_dir}/migration)
else
  commands=(
    "get pods -o wide -n $namespace"
    "get pods -o wide -n $namespace -o yaml"
    "describe pods -n $namespace"
    "get nodes -o wide -n $namespace"
    "get nodes -o wide -n $namespace -o yaml"
    "describe nodes -n $namespace"
    "get events -A"
    "get deploy -o wide -n $namespace"
    "get deploy -o wide -n $namespace -o yaml"
    "describe deploy -n $namespace"
    "get sts -o wide -n $namespace"
    "get sts -o wide -n $namespace -o yaml"
    "describe sts -n $namespace"
    "get csidrivers"
    "get csinodes"
    "get csinodes -o yaml"
    "get all -o wide -n $namespace"
    "describe all -n $namespace"
    "get all -o wide -n $namespace -o yaml"
    "get configmaps -n $namespace"
    "describe namespace $namespace"
    "get namespace $namespace -o yaml"
    "get pvc -n $namespace"
    "get pvc -n $namespace -o yaml"
    "get cm -o yaml -n $namespace"
    "get job,cronjobs -o wide -n $namespace"
    "get applicationbackups -A"
    "get applicationbackups -A -o yaml"
    "get applicationrestores -A"
    "get applicationrestores -A -o yaml"
    "get applicationregistrations -A"
    "get applicationregistrations -A -o yaml"
    "get backuplocations -A"
    "get backuplocations -A -o yaml"
    "get volumesnapshots -A"
    "get volumesnapshots -A -o yaml"
    "get volumesnapshotdatas -A"
    "get volumesnapshotdatas -A -o yaml"
    "get volumesnapshotschedules -A"
    "get volumesnapshotschedules -A -o yaml"
    "get volumesnapshotrestores -A"
    "get volumesnapshotrestores -A -o yaml"
    "get schedulepolicies"
    "get schedulepolicies -o yaml"
    "get sc"
    "get sc -o yaml"
    "get pvc -A"
    "get pv"
 )
 output_files=(
    "k8s_pxb/pxb_pods.txt"
    "k8s_pxb/pxb_pods.yaml"
    "k8s_pxb/pxb_pods_desc.txt"
    "k8s_oth/k8s_nodes.txt"
    "k8s_oth/k8s_nodes.yaml"
    "k8s_oth/k8s_nodes_desc.txt"
    "k8s_oth/k8s_events_all.txt"
    "k8s_pxb/pxb_deploy.txt"
    "k8s_pxb/pxb_deploy.yaml"
    "k8s_pxb/pxb_deploy_desc.txt"
    "k8s_pxb/pxb_sts.txt"
    "k8s_pxb/pxb_sts.yaml"
    "k8s_pxb/pxb_sts_desc.txt"
    "k8s_oth/csidrivers.txt"
    "k8s_oth/csinodes.txt"
    "k8s_oth/csinodes.yaml"
    "k8s_pxb/pxb_all.txt"
    "k8s_pxb/pxb_all_desc.txt"
    "k8s_pxb/pxb_all.yaml"
    "k8s_pxb/pxb_cm.txt"
    "k8s_pxb/pxb_ns_dec.txt"
    "k8s_pxb/pxb_ns_dec.yaml"
    "k8s_pxb/pxb_pvc.txt"
    "k8s_pxb/pxb_pvc.yaml"
    "k8s_pxb/pxb_cm.yaml" 
    "k8s_pxb/pxb_job_cronjob.txt"
    "k8s_bkp/pxb_applicationbackups.txt"
    "k8s_bkp/pxb_applicationbackups.yaml"
    "k8s_bkp/pxb_applicationbackupschedules.txt"
    "k8s_bkp/pxb_applicationbackupschedules.yaml"
    "k8s_bkp/pxb_applicationrestores.txt"
    "k8s_bkp/pxb_applicationrestores.yaml"
    "k8s_bkp/pxb_applicationregistrations.txt"
    "k8s_bkp/pxb_applicationregistrations.yaml"
    "k8s_bkp/pxb_backuplocations.txt"
    "k8s_bkp/pxb_backuplocations.yaml"
    "k8s_bkp/pxb_volumesnapshots.txt"
    "k8s_bkp/pxb_volumesnapshots.yaml"
    "k8s_bkp/pxb_volumesnapshotdatas.txt"
    "k8s_bkp/pxb_volumesnapshotdatas.yaml"
    "k8s_bkp/pxb_volumesnapshotschedules.txt"
    "k8s_bkp/pxb_volumesnapshotschedules.yaml"
    "k8s_bkp/pxb_volumesnapshotrestores.txt"
    "k8s_bkp/pxb_volumesnapshotrestores.yaml"
    "k8s_bkp/pxb_schedulepolicies.txt"
    "k8s_bkp/pxb_schedulepolicies.yaml"
    "k8s_oth/sc.txt"
    "k8s_oth/sc.yaml"
    "k8s_oth/pvc_list.txt"
    "k8s_oth/pv_list.txt"
  )
log_labels=()
migration_commands=()
oth_commands=()
  main_dir="PX_Backup_${namespace}_outputs_$(date +%Y%m%d_%s)"
  output_dir="/tmp/${main_dir}"
  sub_dir=(${output_dir}/logs ${output_dir}/k8s_pxb ${output_dir}/k8s_oth ${output_dir}/k8s_bkp)

fi

# Create a temporary directory for storing outputs
mkdir -p "$output_dir"
mkdir -p "${sub_dir[@]}"
echo "Output will be stored in: $output_dir"
echo "Extraction is in progress"

#Generate Summary file with parameter and date information
summary_file=$output_dir/Summary.txt
echo "Namespace: $namespace">$summary_file
echo "CLI tool: $cli">>$summary_file
echo "option: $option">>$summary_file
echo "Start of generation:" $(date)>>$summary_file

# Execute commands and save outputs to files
for i in "${!commands[@]}"; do
  cmd="${commands[$i]}"
  output_file="$output_dir/${output_files[$i]}"
  #echo "Executing: $cli $cmd"
  $cli $cmd > "$output_file" 2>&1
  #echo "Output saved to: $output_file"
  #echo ""
  #echo "------------------------------------" 
done

# Execute pxctl commands 

for i in "${!pxctl_commands[@]}"; do
  cmd="${pxctl_commands[$i]}"
  echo "cmd: $cmd "
#  output_file="$output_dir/${pxctl_output_files[$i]}"
  #echo "Executing: pxctl $cmd"
#  $cli -n $namespace $pxcmd $cmd > "$output_file" 2>&1 || true
#  echo "Output saved to: $output_file"
#  echo "Return Code: $?"
done

echo "pxctl_commands done"
# Generating Logs
for i in "${!log_labels[@]}"; do
  label="${log_labels[$i]}"
  if [[ "$option" == "PX" ]]; then
    PODS=$($cli get pods -n $namespace -l $label -o jsonpath="{.items[*].metadata.name}")
  else
    PODS=$($cli get pods -n $namespace -o jsonpath="{.items[*].metadata.name}")
  fi
  for POD in $PODS; do
  LOG_FILE="${output_dir}/logs/${POD}.log"
  #echo "Fetching logs for pod: $POD"
  # Fetch logs and write to file
  $cli logs -n "$namespace" "$POD" --tail -1 --all-containers > "$LOG_FILE"
  done
  #echo "Logs for pod $POD written to: $LOG_FILE"
done

# Execute other commands 

for i in "${!oth_commands[@]}"; do
  cmd="${oth_commands[$i]}"
  output_file="$output_dir/${oth_output_files[$i]}"
  #echo "Executing:  $cmd"
  $cmd > "$output_file" 2>&1
  #echo "Output saved to: $output_file"
  #echo ""
  #echo "------------------------------------" 
done

#Execute Migration commands


for i in "${!migration_commands[@]}"; do
  cmd="${migration_commands[$i]}"
  output_file="$output_dir/${migration_ouput[$i]}"
  #echo "Executing: $cli $cmd"
  $cli $cmd > "$output_file" 2>&1
  #echo "Output saved to: $output_file"
  #echo ""
  #echo "------------------------------------" 
done

echo "End of generation:" $(date)>>$summary_file

# Compress the output directory into a tar file
archive_file="${main_dir}.tar"
cd /tmp
tar -cf "$archive_file" "$main_dir"
echo "************************************************"
echo ""
echo "All outputs compressed into: /tmp/$archive_file"
echo ""
echo "************************************************"

# Delete the temporary op directory 
if [[ -d "$output_dir" ]]; then
  rm -rf "$output_dir"
  echo ""
else
  echo ""
fi

echo "Script execution completed successfully."
