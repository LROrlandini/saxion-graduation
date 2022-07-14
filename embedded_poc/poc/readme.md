This folder contains the files for all steps defined for implementing a smart touch detection algorithm for the LED Matrix. These steps are:  
- Data Gathering
- Training and Fitting a ML Model
- Testing the program on the Gadget Board

## Requirements
- Python 3+
- Jupyter Notebook
- USB type-A to Micro-USB connection between computer and gadget board
- Gadget board running latest embedded software found on 'src00' folder on 'neural_network' branch

# Simon Says
The folder contains all scripts required to run Simon Says game. Before first set up, open script 'helper_module.py' and ensure the DATA_PATH variable has the correct directory address.  

# Step 1:
Data gathering can be acomplished by running the Simon Says game. The program must be started without any command line arguments:

```bash
python3 simon_says
```
After choosing the game mode, the logic will start. Red LEDs indicate the instruction.  The beeper indicates when data is being saved. While it beeps, the user should be touching the board where the red LEDs have previously indicated.  
The green LEDs will indicate where the user should have touched. If a mistake is made, the first push button (bottom left) should be pressed during the next beep to delete the last few data entries.

# Step 2
Training and Fitting the ML Model can be acomplished by running the Jupyter Notebook file on root.

# Step 3
Testing the program can be acomplished by running the Simon Says game with a command line argument:

```bash
python3 simon_says 1
```
The user should play the game as normal, touching the screen as required. The game logic will take live readings of the board activity and predict the outputs using the pre-trained model from step 2.

# Service Scripts
The folder contains helper scripts for debugging. The need to be run from root 'scr01' folder so paths will work accordingly:

```bash
python3 service_scripts/<script_name>.py
```

# Board Handler and Data handler
These folders contain modules imported by the simon says game. These should not be ran directly.