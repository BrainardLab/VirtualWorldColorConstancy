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

    b. To change the shape of target object use the option 'objectShapeSet' in RunToyVirtualWorldRecipes.
       Similarly, one can change the shape of inserted light source. If more than one option are provided
       the shape is chosen randomly. 
       To have more than one inserted object/lights, use the option nInsertedObjects/nInsertedLights.
    
    c. Target object position, size and orientation can be set to random using 
       the options targetPositionRandom, targetScaleRandom, targetRotationRandom.
       Similarly, light position and scale can be set to random using lightPositionRandom and lightScaleRandom.

