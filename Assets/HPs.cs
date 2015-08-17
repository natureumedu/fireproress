using UnityEngine;
using System.Collections;

public class HPs : MonoBehaviour {


	public int handsHP = 10;
	public int footsHP = 10;

	// Use this for initialization
	void Start () {
	
	}
	public int getfootHP(){
		return handsHP;

	}

	public void setfootHP(int newX){
		footsHP = footsHP-newX;
	}
	// Update is called once per frame
	void Update () {
	
	}
}
