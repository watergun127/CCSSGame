﻿using UnityEngine;
using System.Collections;

public class BulletScript : MonoBehaviour {
	public Transform startExplosion,endExplosion;
	public float ticks=0;
    GameObject model;
    Vector3 direction;
	// Use this for initialization
	void Start () {
        model=transform.GetChild(0).gameObject;
		if(startExplosion!=null)
		Instantiate(startExplosion, transform.position, transform.rotation);
		direction=transform.TransformDirection(Vector3.forward*75f);	
		//rigidbody.AddForce(direction);
	}
	void End (int explode) {
		if(endExplosion!=null&&explode==1)
		Instantiate(endExplosion, transform.position, transform.rotation);
		GameObject.Destroy(gameObject);
	}
	// Update is called once per frame
	void Update () {
		rigidbody.velocity=direction;
		if(!model.renderer.isVisible)
        	End(0);
	}
	void OnCollisionEnter(Collision collision){
		string name=collision.gameObject.name;
		if(name!="Bullet(Clone)")
		End(1);
	}
}