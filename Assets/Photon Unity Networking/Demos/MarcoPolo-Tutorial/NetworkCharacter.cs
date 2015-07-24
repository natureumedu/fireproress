using UnityEngine;

public class NetworkCharacter : Photon.MonoBehaviour
{
	protected Animator anim;
	private float Speed;
	private Vector3 correctPlayerPos = Vector3.zero; // We lerp towards this
    private Quaternion correctPlayerRot = Quaternion.identity; // We lerp towards this
    // Update is called once per frame
    


	void Update()
    {

		if (!photonView.isMine)
        {
            transform.position = Vector3.Lerp(transform.position, this.correctPlayerPos, Time.deltaTime * 5);
            transform.rotation = Quaternion.Lerp(transform.rotation, this.correctPlayerRot, Time.deltaTime * 5);
        }
    }

    void OnPhotonSerializeView(PhotonStream stream, PhotonMessageInfo info)
    {
        if (stream.isWriting)
        {
            // We own this player: send the others our data
            stream.SendNext(transform.position);
            stream.SendNext(transform.rotation);
			anim = GetComponent< Animator >();
			stream.SendNext(anim.GetFloat("Speed"));
			stream.SendNext(anim.GetFloat("Direction"));
			stream.SendNext(anim.GetBool("Punch_L"));
			stream.SendNext(anim.GetBool("LowKick"));
            stream.SendNext(anim.GetBool("HiKick"));
            stream.SendNext(anim.GetBool("Shoryuken"));

            myThirdPersonController myC = GetComponent<myThirdPersonController>();
            stream.SendNext((int)myC._characterState);
        }
        else
        {
            // Network player, receive data
            this.correctPlayerPos = (Vector3)stream.ReceiveNext();
            this.correctPlayerRot = (Quaternion)stream.ReceiveNext();
			anim = GetComponent< Animator >();
			anim.SetFloat("Speed",(float)stream.ReceiveNext());
			anim.SetFloat("Direction",(float)stream.ReceiveNext());
			anim.SetBool("Punch_L",(bool)stream.ReceiveNext());
			anim.SetBool("LowKick",(bool)stream.ReceiveNext());
            anim.SetBool("HiKick", (bool)stream.ReceiveNext());
            anim.SetBool("Shoryuken", (bool)stream.ReceiveNext());
			
            myThirdPersonController myC = GetComponent<myThirdPersonController>();
            myC._characterState = (CharacterState)stream.ReceiveNext();
        }
    }
 
    }

