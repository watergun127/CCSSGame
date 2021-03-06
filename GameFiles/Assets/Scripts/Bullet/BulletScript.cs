﻿using UnityEngine;
using System.Collections;

public class BulletScript : MonoBehaviour {
	public Transform startExplosion,endExplosion;
	public GameObject Shooter;
	public float lifeSpan=5.0f;
    GameObject model;
    Vector3 direction;
    LineRenderer line;

	void Start () {
        line=gameObject.GetComponent<LineRenderer>();
        line.enabled=false;
		if(startExplosion!=null)
		Instantiate(startExplosion, transform.position, transform.rotation);
		direction=transform.TransformDirection(Vector3.forward*50f);	
	}
	void End (int explode,Vector3 collisionPos) {
		if(endExplosion!=null&&explode==1)
			Instantiate(endExplosion, transform.position, transform.rotation);
		GameObject.Destroy(gameObject);
	}

	void Update () {
		lifeSpan-=Time.deltaTime;
		if(lifeSpan<=0.0f) End(0,Vector3.zero);
		transform.Translate(direction*Time.deltaTime,Space.World);
		Ray ray=new Ray(transform.position,transform.forward);
		Vector3 start=ray.GetPoint(0f),end=ray.GetPoint(2f);
		RaycastHit hit;
		Physics.Raycast(ray, out hit, 1.0F);
		if(hit.transform!=null)
			HandleCollision(hit);
		line.SetPosition(0,start);
        line.SetPosition(1,end);
        line.enabled=true;
	}
	void HandleCollision(RaycastHit c){
		GameObject go=c.transform.gameObject;
		bool canCollide=(go!=Shooter&&go!=null)&&go.tag!="Explosion";
		if(canCollide){
			if(go.tag=="Enemy") go.GetComponent<EnemyScript>().getHurt(1,go);
			else if (go.tag=="Powerup") go.GetComponent<PowerUpBaseScript>().getHit();
			else if(go.tag=="Player") go.GetComponent<MovementScript>().getHurt(1);
			End(1,c.point);
		}
	}
	void OnBecameInvisible() {
    	End(0,Vector3.zero);   
    }
}
