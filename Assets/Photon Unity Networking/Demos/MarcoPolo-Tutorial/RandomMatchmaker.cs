using UnityEngine;

public class RandomMatchmaker : Photon.PunBehaviour
{
    private PhotonView myPhotonView;
    private float nameCount;
    PhotonPlayer[] players;
    // Use this for initialization
    void Start()
    {
        PhotonNetwork.ConnectUsingSettings("0.1");


    }

    public override void OnJoinedLobby()
    {
        Debug.Log("JoinRandom");
        PhotonNetwork.JoinRandomRoom();
    }

    public void OnPhotonRandomJoinFailed()
    {
        PhotonNetwork.CreateRoom(null);
    }

    public override void OnJoinedRoom()
    {

        GameObject player = PhotonNetwork.Instantiate("UnityMask", Vector3.zero, Quaternion.identity, 0);

        player.GetComponent<myThirdPersonController>().isControllable = true;
        player.GetComponent<ThirdPersonCamera>().enabled = true;
        PhotonPlayer[] players = PhotonNetwork.playerList;

        // プレイヤー名とIDを表示.
        for (int i = 0; i < players.Length; i++)
        {
            Debug.Log((i).ToString() + " : " + players[i].name + " ID = " + players[i].ID);
        }


    }
}
