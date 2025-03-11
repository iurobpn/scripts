# brave search version
import bpy
import multiprocessing

def apply_decimate_modifier(obj, decimate_type, ratio):
    """
    Apply the decimate modifier to a given object.
    
    :param obj: The object to decimate.
    :param decimate_type: Type of decimation (e.g., 'COLLAPSE', 'UNSUBDIV', 'DISSOLVE').
    :param ratio: Ratio for decimation.
    """
    decimate_mod = obj.modifiers.new(name="Decimate", type='DECIMATE')
    decimate_mod.decimate_type = decimate_type
    decimate_mod.ratio = ratio
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Decimate")

def main(input_obj, decimate_type, ratio):
    # Import the .obj file
    bpy.ops.wm.obj_import(filepath=input_obj)
    
    # Select all imported objects
    imported_objects = [obj for obj in bpy.context.selected_objects]
    
    # Create a pool of worker processes
    with multiprocessing.Pool(processes=multiprocessing.cpu_count()) as pool:
        # Apply the decimate modifier to each object in parallel
        pool.starmap(apply_decimate_modifier, [(obj, decimate_type, ratio) for obj in imported_objects])

if __name__ == "__main__":
    input_obj = "path/to/your/model.obj"
    decimate_type = 'COLLAPSE'
    ratio = 0.5
    main(input_obj, decimate_type, ratio)
