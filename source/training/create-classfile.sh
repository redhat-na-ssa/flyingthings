#/bin/sh
# set -x

pushd datasets || exit 0

NC=$(cat classes.txt | wc -l)

create_json_array(){
  NAMES=$( printf "'%s'," "${LIST[@]}" )
  NAMES="[${NAMES: : -1}]"
  # echo "${NAMES}"
}

create_names_array(){
  LIST=()

  local IFS=''
  while read ITEM
  do
    LIST+=(${ITEM})
  done < classes.txt
}

create_classes_yaml(){

  create_names_array
  create_json_array

cat > classes.yaml <<YAML
path: training
train: train/images
val: valid/images
test: test/images

nc: ${NC}
names: ${NAMES}
YAML

cat classes.yaml && \
mv classes.yaml ../

}

create_classes_yaml
popd
