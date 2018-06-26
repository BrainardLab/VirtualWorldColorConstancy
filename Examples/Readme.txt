%% Steps to render images using VirtualWorldColorConstancy.

1. The function that can be used to render images for a particular condition 
    is called RunToyVirtualWorldRecipes.m. This function calls the two main 
    functions of VWCC, MakeToyRecipesByCombinations and 
    ConeResponseToyVirtualWorldRecipes. The first function renders the images.
    The second function simulates the response of the retinal cones.

    Read the function descriptions for the input options.

2. To make sure that everything was installed properly type:

    RunToyVirtualWorldRecipes()

    This will render 4 images and save the output in the folder 
    ExampleOutput on your output path.

3. The script to render images for the 3 conditions used in the luminance 
   constancy paper are given in this folder. These are named Condition1.m, 
   Condition2.m, Condition3.m.

4. There are some additional scripts in this folder to illustrate how VWCC works.

    a. RenderABaseScene: This function can be used to render one of 6 base scenes.
    b. RunToyVirtualWorldRecipes has options to insert objects in the base scene.
       For example, 
    RunToyVirtualWorldRecipes('baseScenseSet',{'Library'},'objectShapeSet',{'RingToy'});
    will insert the object RingToy in the basescene library. 
    Similarly, one can add additional lights.

5. To generate images at multiple luminance levels with the same relative shape of target 
    object reflectance spectrum (similar to Figure 5:Condition 1-3 in the paper) use the option
    targetReflectanceScaledCopies.

    RunToyVirtualWorldRecipes('targetReflectanceScaledCopies',true);

6. To make cropped image montage as in Figure 5, use the function:
    makeCroppedImageMontage

    Example: For luminance levels [0.2 0.4 0.6] each with 5 images:

    makeCroppedImageMontage('pathToFolder',[0.2 0.4 0.6], [1:5],0.005);

    Where 'pathToFolder' is the path to the condition fodler.
    The montage would be saved in 'pathToFolder' as a .eps file.
