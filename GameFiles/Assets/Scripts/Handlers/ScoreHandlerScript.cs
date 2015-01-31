﻿using UnityEngine;
using UnityEditor;
using System.Collections;

public class ScoreHandlerScript : MonoBehaviour {
    public float totalScore=0,additiveScore=0,multiplier=0,scoreUnit=100;
    float additiveAddTimer=0,additiveAddTime=4,totalScoreAdditive=10,totalScoreGoal=0;
    public MovementScript player;
	// Use this for initialization
	void Start () {
	   player=GameObject.Find("Player").GetComponent<MovementScript>();
       totalScore=Game.current.score;
       totalScoreGoal=Game.current.score;
	}
	
	// Update is called once per frame
	void Update () {
        if(multiplier>99.9f) multiplier=99.9f;
    	if(additiveAddTimer<=0&&additiveScore*multiplier>0){
    		totalScoreGoal+=additiveScore*multiplier;
    		additiveScore=0;
    		multiplier=0;
    		totalScoreAdditive=(totalScoreGoal-totalScore)/25;
    	}
    	else additiveAddTimer-=Time.deltaTime;
    	if(totalScore<totalScoreGoal) totalScore+=totalScoreAdditive;
    	else if(totalScore>totalScoreGoal) totalScore=totalScoreGoal;
        Game.current.score+=totalScoreGoal-totalScore;         
        if(player.isDead){
            Game.current.deaths+=1;
        }
        if(Input.GetButtonDown("Quit")){
            SaveLoad.Save();
            EditorApplication.isPlaying=false;
            Application.Quit();
        }
	}
    public void EnemyDestroyed(int value,float toAddToMultiplier){
         if(multiplier==0&&toAddToMultiplier!=0) multiplier=1;
         else multiplier+=toAddToMultiplier;
         additiveScore+=value*scoreUnit; 
         additiveAddTimer=additiveAddTime;             
    }

    public void claimCombo(){
        additiveAddTimer=0;
    }
}
