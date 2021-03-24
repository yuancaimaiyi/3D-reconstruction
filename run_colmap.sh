DATASET_PATH=$1
IMAGE_PATH=$2
GPU_IDX=$3
COLMAP=/home/licheng/opt/colmap/bin/colmap

if [ ! -f $DATASET_PATH/cam_para ]
then
    echo "No Camera File Found"
    exit -1
fi

if [ ! -d $DATASET_PATH/sparse ]
then
    mkdir $DATASET_PATH/sparse
fi

if [ ! -d $DATASET_PATH/dense ]
then
    mkdir $DATASET_PATH/dense
fi

CAM_MODEL=$(awk '{print $1}' $DATASET_PATH/cam_para)
CAM_PARAS=$(awk '{print $2}' $DATASET_PATH/cam_para)

$COLMAP feature_extractor \
    --database_path $DATASET_PATH/database.db \
    --image_path $DATASET_PATH/$IMAGE_PATH \
    --ImageReader.camera_model $CAM_MODEL \
    --ImageReader.camera_params $CAM_PARAS \
    --ImageReader.single_camera 1 \
    --SiftExtraction.estimate_affine_shape 1 \
    --SiftExtraction.domain_size_pooling 1 \
    --SiftExtraction.gpu_index $GPU_IDX

$COLMAP sequential_matcher \
    --database_path $DATASET_PATH/database.db \
    --SiftMatching.max_error 10 \
    --SiftMatching.max_distance  1.0 \
    --SiftMatching.max_ratio 0.9 \
    --SequentialMatching.overlap 10 \
    --SiftMatching.guided_matching 1
$COLMAP mapper \
    --database_path $DATASET_PATH/database.db \
    --image_path $DATASET_PATH/$IMAGE_PATH/ \
    --output_path $DATASET_PATH/sparse \
    --Mapper.filter_max_reproj_error 10.0 \
    --Mapper.multiple_models 0 \
    --Mapper.init_max_forward_motion 0.99998 \
    --Mapper.init_min_tri_angle 4 \
    --Mapper.ba_refine_focal_length 0 \
    --Mapper.ba_refine_principal_point 0 \
    --Mapper.ba_refine_extra_params 0


$COLMAP image_undistorter \
    --image_path $DATASET_PATH/$IMAGE_PATH \
    --input_path $DATASET_PATH/sparse/0 \
    --output_path $DATASET_PATH/dense \
    --output_type COLMAP \
    --max_image_size 2000

$COLMAP patch_match_stereo \
    --workspace_path $DATASET_PATH/dense \
    --workspace_format COLMAP \
    --PatchMatchStereo.geom_consistency true

$COLMAP stereo_fusion \
    --workspace_path $DATASET_PATH/dense \
    --workspace_format COLMAP \
    --input_type geometric \
    --output_path $DATASET_PATH/dense/fused.ply



