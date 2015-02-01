﻿using UnityEngine;
using UnityEditor;
using UnityEngine.UI;
using System.Collections;

public class MainMenu2 : MonoBehaviour {
	public enum Menu {
		MainMenu,
		NewGame,
		Continue
	}
	public Menu currentMenu=Menu.MainMenu;
	public GameObject[] canvases=new GameObject[3];
	// Use this for initialization
	void Start () {
		SaveLoad.Load();
		canvases[0]=GameObject.Find("MainMenuCanvas");
		canvases[1]=GameObject.Find("LoadGameCanvas");
		canvases[2]=GameObject.Find("NewGameCanvas");
		GameObject.Find("LoadGameCanvas/LoadGameDialog/LoadGameData").GetComponent<Text>().text=Game.current.name+"\n\n"+Game.current.score;
		//Button[] buttons=canvases[0].GetComponentsInChildren<Button>();
		//buttons[0].onClick.AddListener(() => { this.NewGameButtonClicked();});
		//buttons[0].onClick.AddListener(NewGameButtonClicked);
	}
	
	// Update is called once per frame
	void Update () {
		enableCorrectCanvas();

	}
	void enableCorrectCanvas(){
		canvases[0].SetActive(currentMenu==Menu.MainMenu);
		canvases[1].SetActive(currentMenu==Menu.Continue);
		canvases[2].SetActive(currentMenu==Menu.NewGame);
	}
	public void NewGameButtonClicked(){
		currentMenu=Menu.NewGame;
	}
	public void LoadGameButtonClicked(){
		currentMenu=Menu.Continue;
	}
	public void QuitButtonClicked(){
		Application.Quit();
		EditorApplication.isPlaying=false;
	}
	public void ConfirmLoadGame(){
		Application.LoadLevel(1);
	}
	public void ConfirmNewGame(){
		Game.current.name=GameObject.Find("NewGameCanvas/InputField/Text").GetComponent<Text>().text;
		SaveLoad.Save();
		Application.LoadLevel(1);
	}
	public void ToMainMenu(){
		currentMenu=Menu.MainMenu;
	}
}