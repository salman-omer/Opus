# Opus - A Mobile Music Learning Game

Rutgers ECE Capstone group S20-15 <br />
Team members: 

Justin May:  https://github.com/justinmay <br />
Salman Omer: https://github.com/salman-omer <br />
Yash Shah: https://github.com/shahhyash <br />
Skyler Lee: https://github.com/Only16Characters <br />
Jonathan Hong: https://github.com/hejeong <br />


Check out our project overview and presentation! <br />
[![Alt text](https://img.youtube.com/vi/Saf03aXb4ww/0.jpg)](https://www.youtube.com/watch?v=Saf03aXb4ww)<br />



# Abstract <br />

Popular play-along music games, such as “Guitar Hero” and “Rock Band”, currently allow users to play along in real time to a song using a controller designed to mimic an actual instrument. For example, the guitar controller has five colored buttons that are to be pressed in different combinations using the left hand, and a strum bar to be pressed by your right hand to imitate strumming. The players are then given a visual aid of five vertical lines, each line corresponding to a button for the left hand. Bubbles automatically scroll down these lines and the player must be pressing the correct buttons with their left hand while hitting the strum bar with their right. While users may learn and gain a stronger intuition of some musical concepts such as rhythm, the skills required to play these games will not translate into playing the actual corresponding instrument because of how simplified the controller is. <br />

Thus, our project is a musical game where the controller is a real, physical piano instead of an electronic-instrument analog. As a result, the player would learn more skills necessary for playing real instruments than they would learn from playing traditional music games like “Rock Band”. Using signal processing, we will be able to accurately identify what notes are played based on their frequencies and will also determine the timing of these notes.   <br />

# How to Compile <br />

Clone the repository and open the uaal_demp.xcworkspace in XCode. Compile "native_app" directly to your iPhone device. Compiling any of the individual frameworks or not using a physical device will result in errors. Since we do not have proper Apple Development licensing on this project, you may have to change your account settings to compile properly. XCode will throw errors which can be resolved by clicking on XCode -> Preferences -> Accounts. Then add a development account (either a github or Apple ID). Then try to compile again. Resolve errors regarding the publishing account by changing the publishing team to your inputted account as indicated. Lastly, run `pod init` to install cocaopods packages in the base directory, If you need help, please don't hesitate to contact us! <br />

# How to Update Game Code in the App <br />

If you have changed code from the Unity project and need to compile to Xcode, you need to follow a few specific steps. In Unity, select the target OS as iOS and select "Build". When you build, build it to this repo's base directory as "my_unity_app" and overwrite everything that is here. Once you have done so, go into XCode and select "iPhone-Unity" in the file explorer on the left. In the preferences window that opens on the right, uncheck anything that is checked under "Targets" and check "Unity Framework". This will allow iOS to see Unity properly. <br />

# Supporting Documents <br />

Final Project Report is currently under works. It will be fully prepared in time for the expo on April 29th. <br />

Deep Learning Considerations: <br />
https://docs.google.com/document/d/1PLDvvPvsz-DQcnQ9AgptQ8enyhh4AYGp2_As62TphpA/edit?usp=sharing

# References <br />
"Multiple Pitch Estimation Based on Modified Harmonic Product Spectrum" - https://bit.ly/2yzUcbF
