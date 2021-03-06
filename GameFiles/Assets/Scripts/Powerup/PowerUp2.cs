﻿using UnityEngine;
using System.Collections;

public class PowerUp2 : PowerUpBaseScript {
	int health,maxhealth=5;
	// Use this for initialization
	void Start () {
		health=maxhealth;
	}
	
	// Update is called once per frame
	void Update () {
		transform.localPosition=Vector3.zero;
	}
	public override void getHit(){
		print("GotHit");
		health--;
		Color c=gameObject.renderer.material.GetColor("_TintColor");
		c.a=(float)health/(float)maxhealth;
		gameObject.renderer.material.SetColor("_TintColor",c);
		if (health<=0)
			Destroy(gameObject);
	}
}
